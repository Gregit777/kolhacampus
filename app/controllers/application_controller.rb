class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  respond_to :json, :html #all controllers respond to JSON & HTML requests

  before_action :check_platform, :add_jader_views_to_path, :set_locale

  layout Proc.new { |controller| controller.request.path =~ /admin|login/ ? 'admin' : (controller.request.format == 'json' ? false : @platform) }

  helper_method :search_engine?, :active_schedule

  rescue_from CanCan::AccessDenied do |exception|
    render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
  end

  ### Helper Methods

  # CanCan ability
  def current_ability
    @current_ability ||= Ability.new(current_user)
  end

  # Helper method to check if request came from search engine or not
  def search_engine?
    @_se ||= (@platform == 'web' && browser.user_agent.match(/\(.*https?:\/\/.*\)/)) || params[:se] == '1'
  end

  # Helper method to get currently active schedule
  def active_schedule
    @_schedule = Schedule.active
  end

  private

  # Check which platform user is on (desktop / mobile) and determine request format accordingly
  def check_platform
    mobile_override     = params[:mobile] && params[:mobile] == "1"
    desktop_override    = params[:mobile] && params[:mobile] == "0"
    if ( (browser.mobile? and !browser.ipad?) or mobile_override ) and !request.xhr? and !desktop_override
      @platform = 'mobile'
      request.format = :mobile
    else
      @platform = 'desktop'
    end
  end

  # Add Jader views to ActionView render path based on platform
  def add_jader_views_to_path
    path = Rails.root.join('app','assets','javascripts','apps', @platform, 'templates')
    prepend_view_path path
  end

  # Set current locale
  def set_locale
    if request.path =~ /admin|login/
      I18n.locale = :en
    else
      I18n.locale = request.cookies['locale'] || :he
    end
  end
end
