class MobileUseragentConstraint
  def initialize
  end

  def matches?(request)
    return false if [Mime::JPEG, Mime::PNG, Mime::GIF].include?(request.format)
    return false if request.path.start_with?('/admin')
    if request.params[:mobile] == "0"
      request.cookie_jar['mobile'] = nil
      return false
    end
    cookies = request.cookie_jar
    has_cookie = cookies['mobile'] == '1'
    if has_cookie
      true
    else
      mobile_override = request.params[:mobile] && request.params[:mobile] == "1"
      browser = Browser.new user_agent: request.headers['HTTP_USER_AGENT']
      is_mobile = (browser.mobile? && !browser.ipad?) || mobile_override
      request.cookie_jar['mobile'] = '1' if is_mobile && !request.xhr?
      is_mobile && !request.xhr?
    end
  end
end