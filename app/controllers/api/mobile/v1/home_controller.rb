class Api::Mobile::V1::HomeController < ApplicationController

  def index
    config = ::Configuration.home
    home_data, components_data = config.home_config_items
    results = Home.load_items(home_data, components_data)
    render json: results.to_json
  end

end
