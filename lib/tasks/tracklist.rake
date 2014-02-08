# coding: utf-8
require 'nokogiri'
require 'cgi'
require "uri"
require 'json'
require 'net/http'

namespace :kolhacampus do

  desc "Fetch tracks"
  task :get_latest_tracks => :environment do
    TrackReader.init
    cur_program_id = TrackReader.find_program_id_by_date(Time.now)
    program = Program.find(cur_program_id)
    return if program.is_set?
    TrackReader.init_current_program_track
    Rails.logger.info "Fetching tracks for program #{program.name}"
    if program.live?
      results = TrackReader.fetch_last_fm
    else
      results = TrackReader.fetch_onair_now
    end
    if results.any?
      Rails.logger.info "Got new tracks... Processing"
      TrackReader.process_tracks(results)
    else
      Rails.logger.info "No new tracks"
    end
  end

end

class TrackReader

  URL = 'http://ws.audioscrobbler.com/2.0/user/info106fm/recenttracks.rss'

  class << self

    def init
      @schedule = Schedule.active
      @conf = @schedule.configuration.to_hash
    end

    def fetch_last_fm
      Rails.logger.info "Fetching tracks for last.fm"
      last_tracklist = RawTracklist.find_or_create_by(source: 'lastfm')
      uri = URI.parse(URL)
      response = Net::HTTP.get_response(uri)
      rss = response.body
      doc = Nokogiri::XML(rss) do |config|
        config.strict.noent.noblanks
      end
      e = doc.xpath('//lastBuildDate')
      current_build = date_to_local(e.first.inner_text, 'last.fm')
      if last_tracklist.last_run.to_i == current_build.to_i
        Rails.logger.info "No new tracks found on last.fm"
        return []
      end
      items = doc.xpath('//item')
      results = []
      Rails.logger.info "Found #{items.size} new tracks on last.fm"
      items.each do |item|
        o = {}
        item.children.each do |child|
          case child.name
            when 'pubDate' then o['start_time'] = date_to_local(child.inner_text, 'last.fm')
            when 'title'
              o['artist'], o['track'] = ActiveSupport::Multibyte::Chars.new(child.inner_text).mb_chars.normalize(:kd).split(/\xE2\x80\x93/).map{|s| s.to_s }
          end
        end
        results << o
      end
      last_tracklist.update_attributes(:last_run => current_build, :results => results)
      results
    end

    def fetch_onair_now
      Rails.logger.info "Fetching tracks from broadcast_monitor.xml"
      last_tracklist = RawTracklist.find_or_create_by(source: 'onair')
      rss_file = File.join(Rails.root,'tmp/xml/broadcast_monitor.xml')
      unless File.exists? rss_file
        Rails.logger.info "broadcast_monitor XML file not found"
        return []
      end
      doc = Nokogiri::XML(File.open(rss_file)) do |config|
        config.strict.noent.noblanks
      end
      e = doc.xpath('//updated')
      current_build = date_to_local(e.first.inner_text,'onair_now') unless e.blank?
      if last_tracklist.last_run.to_i == current_build.to_i
        Rails.logger.info "No new tracks found in broadcast_monitor XML"
        return []
      end
      items = doc.xpath('//Current')
      results = []
      Rails.logger.info "Found #{items.size} new tracks in broadcast_monitor XML"
      items.each do |item|
        o = {}
        item.children.each do |child|
          case child.name
            when 'startTime' then o['start_time'] = date_to_local(child.inner_text,'onair_now')
            when 'titleName' then o['track'] = child.inner_text
            when 'artistName' then o['artist'] = child.inner_text
          end
        end
        results << o
      end
      last_tracklist.update_attributes(:last_run => current_build, :results => results)
      results
    end

    def date_to_local(str, source)
      case source
        when 'last.fm'
          DateTime.strptime(str,'%a, %d %b %Y %H:%M:%S %z').to_time.utc.getlocal
        when 'onair_now'
          (DateTime.strptime(str,'%Y-%m-%dT%H:%M:%S.%L').to_time - Time.now.gmt_offset).getlocal
      end
    end

    def process_tracks(tracks)
      Rails.logger.info "Processing new tracks"
      cur_program_id = nil
      prev_program_id = nil
      programs = {}
      tracks.each do |track|
        cur_program_id = find_program_id_by_date(track['start_time'])
        if cur_program_id.nil? or cur_program_id != prev_program_id
          programs[cur_program_id] = {
            :start_time => @schedule.resolved_start_time(track['start_time']),
            :tracks => []
          }
        end
        programs[cur_program_id][:tracks] << track
        prev_program_id = cur_program_id
      end
      Rails.logger.debug "Saving found tracks"
      Rails.logger.debug programs.inspect
      save_program_tracks(programs)
    end

    def find_program_id_by_date(date)
      @conf[date.hour.to_s][(date.wday+1).to_s]
    end

    def save_program_tracks(programs)
      programs.each do |program_id, data|
        Rails.logger.info "Processing tracks for program #{program_id}"
        publish_at = data[:start_time]
        tracklist = Tracklist.find_by_program_id_and_publish_at(program_id,publish_at)
        if tracklist.nil?
          Rails.logger.info "No existing track found for program #{program_id} at #{publish_at}"
          next
        end
        Rails.logger.info "Saving new tracks to track #{tracklist.id}"
        tracklist.tracks ||= {}.with_indifferent_access
        tracklist.tracks.delete_if { |c, item| item['track'].blank? }
        tracks = data[:tracks].sort_by { |item| (item['start_time'] || 0).to_i }
        c = tracklist.tracks.values.size + 1
        tracks.each do |item|
          next if tracklist.tracks.values.map{|v| v['track'] }.include?(item['track'])
          new_item = {
            'track' => item['track'],
            'artist' => item['artist'],
            'start_time' => item['start_time'].to_time.strftime('%H:%M:%S')
          }.with_indifferent_access
          get_track_info(new_item)
          Rails.logger.info "Adding new item to tracklist: #{new_item.inspect}"
          tracklist.tracks[c.to_s] = new_item
          c += 1
        end
        Rails.logger.info "Saving track #{tracklist.id}"
        tracklist.save
      end
    end

    def init_current_program_track
      Rails.logger.info "Initializing new track for current program"
      now = Time.now
      program_id = find_program_id_by_date(now)
      publish_at = @schedule.resolved_start_time(now)
      Rails.logger.info "Current program ID is #{program_id}"
      Rails.logger.info "Current program starts at #{publish_at}"
      tracklist = Tracklist.find_or_create_by(program_id: program_id, publish_at: publish_at)
      Rails.logger.info "Initialized track #{tracklist.id}"
    end

    def get_track_info(track)
      url = 'http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=a33e55dc41b88406dcaf03b5ae1cf6b4&artist=%s&track=%s&format=json' % [CGI::escape(track['artist']),CGI::escape(track['track'])]
      uri = URI.parse(url)
      Rails.logger.info "Checking Last.fm for track info #{url}"
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      Rails.logger.info "Got response from Last.fm #{data.inspect}"
      return if data['error'] || data['track']['album'].nil?
      album = data['track']['album']
      track['album'] = album['title']
      track['image'] = album['image'].select {|img| img['size'] == 'medium'}.first['#text']
    end
  end

end