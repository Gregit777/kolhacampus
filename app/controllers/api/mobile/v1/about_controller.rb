class Api::Mobile::V1::AboutController < ApplicationController

  def index
    config = ::Configuration.about
    locale = I18n.locale == :en ? 'english' : 'hebrew'
    text = config.about_config_items[locale]

    render json: [{id: 1, text: text}]
  end

end
