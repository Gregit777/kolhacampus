require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Kolhacampus
  class Application < Rails::Application
    config.time_zone = 'Jerusalem'
    config.active_record.default_timezone = :local
    I18n.enforce_available_locales = false

    config.encoding = "utf-8"

    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Enable the asset pipeline
    config.assets.enabled = true
    config.serve_static_assets = false
    config.assets.initialize_on_precompile = true
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.paths << Rails.root.join("vendor", "assets", "swf")
    config.assets.paths << Rails.root.join("vendor", "assets", "images")
    config.assets.precompile += %w( apps/mobile/app.js apps/mobile/vendor.js apps/mobile/views_preloader.js apps/mobile/app.css modernizr.custom.js active_admin.css active_admin.js )

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end
