class Tracklist < ActiveRecord::Base

  include Tire::Model::Search
  include Tire::Model::Callbacks
  include I18n::Model

  settings :analysis => {
    :filter => {
      :title_ngram  => {
        "type"     => "edgeNGram",
        "max_gram" => 15,
        "min_gram" => 2
      }
    },
    :analyzer => {
      :index_ngram_analyzer => {
        "type" => "custom",
        "tokenizer" => "standard",
        "filter" => [ "standard", "lowercase", "title_ngram" ]
      },
      :search_ngram_analyzer => {
        "type" => "custom",
        "tokenizer" => "standard",
        "filter" => [ "standard", "lowercase"]
      },
    }
  }

  mapping do
    indexes :id,          index: :not_analyzed
    indexes :description, analyzer: 'snowball'
    indexes :publish_at,  type: 'date'
    indexes :status,      type: 'integer'
    indexes :title,       :type => 'multi_field', :fields => {
      :title => { :type => "string"},
      :"title.autocomplete" => { :search_analyzer => "search_ngram_analyzer", :index_analyzer => "index_ngram_analyzer", :type => "string"}
    }
  end

  # Associations
  belongs_to :program

  # Serializations
  serialize :tracks, JSON
  serialize :feed, JSON

  # Callbacks
  after_initialize :after_initialize
  before_save :clean_empty_tracks
  before_save :auto_fill_start_times
  before_save :add_tracks_ids
  after_save :update_tracklist_count
  after_destroy :update_tracklist_count

  # Acts as taggable
  #acts_as_taggable

  # Scopes
  scope :recent, -> {
    self.find_by_sql("
      select tr.id, tr.program_id, tr.description, tr.publish_at, tr.tracks, tr.ondemand_url, tr.updated_at, tr.feed from
      (select id,max(publish_at) as the_date from tracklists where publish_at <= now() and ondemand_url is not null and ondemand_url <> '' and tracks is not null group by id order by publish_at desc) as tr1
      inner join tracklists as tr on tr.id = tr1.id
      inner join programs as pr on tr.program_id = pr.id
      where pr.active = 1
      group by tr.program_id
      order by tr.publish_at desc
      limit 20
    ")
  }

  scope :for_program, ->(id) { where('program_id = ?', id).where.not('tracks' => nil, 'tracks' => "{}").order('publish_at desc').limit(30) }

  scope :on_homepage, -> (limit = 3, ids = []) { where("status >= ? and now() >= publish_at and id not in (?)" , Status::Confirmed, ids).order("publish_at asc").limit(limit) }

  def to_s
    title
  end

  def title
    self.program ? [self.program.name, self.publish_at.strftime("%d-%m-%Y")].join(' ') : nil
  end

  def feed_items
    items = tracks.values.map{|track|
      track['type'] = 'track'
      track['image'] = self.program.image.small.url unless track.key?('image')
      track
    }

    now = Time.now
    items.each_with_index do |item, index|
      feed_items = feed.select{|f| f['id'] == item['id']}.first
      item['feed'] = feed_items['feed'] unless feed_items.nil?
      if index == 0
        h,m,s = item['start_time'].split(':')
        item['start_time'] = [h, '00', '00'].join(':')
      end
    end

    items.delete_if do |item|
      h,m,s = item['start_time'].split(':').map{|i| i.to_i }
      t = Time.new publish_at.year, publish_at.month, publish_at.day, h, m, s
      t > now
    end

    items.sort do |a, b|
      a['start_time'] <=> b['start_time']
    end
  end

  def related_track(id)
    r = tracks.select{|k,v| v['id'] == id }
    r.any? ? r.values.first : nil
  end

  def start_time
    self.publish_at.strftime('%H:00')
  end

  def to_indexed_json
    to_json(methods: [:title], only: [:id, :title, :description, :publish_at, :status])
  end

  def self.get_item_feed_object(item_id, start_time)
    o = {
      'id' => (item_id.blank? ? SecureRandom.hex(4) : item_id),
      'feed' => []
    }
    o['start_time'] = start_time unless start_time.nil?
    o.with_indifferent_access
  end

  private

  def after_initialize
    if new_record?
      self.tracks = {
        "0" => {'start_time' => '', 'track' => '', 'album' => '', 'artist' => '', 'label' => ''}
      }
      self.publish_at = Time.now if publish_at.nil?
    end
    self.tracks ||= {}
    self.feed ||= []
  end

  def auto_fill_start_times
    return unless tracks.values.any?
    with_start_time = tracks.values.select{|track| !track.with_indifferent_access['start_time'].blank? }
    if with_start_time.size == 0
      n = tracks.values.select{|track| track.with_indifferent_access.key? 'track' }.size
      t = publish_at.dup
      step = (60 * 60 / n)
      tracks.values.each do |track|
        next unless track.with_indifferent_access.key? 'track'
        track['start_time'] = t.getlocal.strftime('%H:%M:%S')
        t += step
      end
    end
  end

  def add_tracks_ids
    return unless tracks.values.any?
    tracks.each do |n,track|
      next if track.key? 'id'
      track['id'] = SecureRandom.hex(4)
    end
  end

  def clean_empty_tracks
    self.tracks.delete_if{|k, track|
      track['track'].blank? && track['start_time'].blank?
    }
  end

  def update_tracklist_count
    prog = self.program
    count = Tracklist.where(program_id: prog.id).where.not(ondemand_url: nil).count
    prog.update_attribute :tracklist_count, count
  end

end
