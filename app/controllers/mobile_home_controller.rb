class MobileHomeController < ApplicationController

  def index
    now = Time.now
    @program = active_schedule.current_program
    start_time = active_schedule.resolved_start_time(now)
    @tracklist = Tracklist.where('program_id = ? and publish_at = ?', @program.id, start_time).first
    if @tracklist.nil?
      @tracklist = Tracklist.create program_id: @program.id, publish_at: start_time
    end
    navigation_categories = ::Configuration.navigation.data['categories']
    @categories = Category.for_navigation(navigation_categories)
    render :template => 'layouts/mobile', :layout => nil
  end

end
