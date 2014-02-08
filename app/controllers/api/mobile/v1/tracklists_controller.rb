class Api::Mobile::V1::TracklistsController < ApiController

  def index
    if params[:program_id]
      @tracklists = Tracklist.for_program(params[:program_id])
    else
      @tracklists = Tracklist.recent
    end
  end

  def show
    @tracklist = Tracklist.find params[:id]
    updated_at = Time.strptime(params[:updated_at],'%FT%T').to_time unless params[:updated_at].nil?
    if updated_at.nil? || @tracklist.updated_at > updated_at
      render
    else
      render :nothing => true
    end
  end

  def by_datetime
    d = Time.strptime(params[:datetime],'%Y-%m-%dT%H:%M')
    @tracklist = Tracklist.where(:publish_at => d).first
    if @tracklist.nil?
      @tracklist = Tracklist.create :publish_at => d, :program_id => params[:program_id]
    end
    render :action => :show
  end

  def add_comment
    @tracklist = Tracklist.find(params[:id]) or (render(nothing: true, status: 500) and return)
    comment = params[:comment].dup
    comment['type'] = 'comment'
    m = comment[:message].match(/@\S+/)
    unless m.nil?
      user_name = m[0]
      if user = Twitter.user(user_name)
        comment['image'] = user[:profile_image_url]
        comment['message'].gsub!(user_name, '')
        comment['user'] = {
          'name' => user[:name],
          'screen_name' => user[:screen_name]
        }
      end
    end
    item = @tracklist.feed.select{|item| item['id'] == comment['item_id']}.first
    if item.nil?
      item = Tracklist.get_item_feed_object(comment['item_id'], Time.now.strftime('%H:%M:%S'))
      @tracklist.feed << item
    end

    comment.delete('item_id')
    comment['image'] = nil unless comment.key?('image')
    item['feed'] << comment
    if @tracklist.save
      render 'api/mobile/v1/tracklists/show'
    else
      render nothing: true, status: 500
    end
  end

end
