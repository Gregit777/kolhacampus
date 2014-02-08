class Configuration < ActiveRecord::Base

  DELIMITER = '~|~'

  self.table_name = 'configuration'

  serialize :data, JSON

  scope :home, -> { find_by(name: 'home') }

  scope :navigation, -> { find_by(name: 'navigation') }

  scope :about, -> { find_by(name: 'about') }

  before_save :format_data
  after_initialize :format_data

  def home_config_items
    home_components = Hash[Configuration.find_by(name: 'home_components').data.collect{|k,v| [k, v.to_i] }]
    [data, home_components]
  end

  def home_components_config_items
    data
  end

  def navigation_config_items
    data
  end

  def about_config_items
    data
  end

  def format_data
    m = ('format_' + name + '_data').to_sym
    send(m) if respond_to?(m)
  end

  def format_home_data
    now = Time.now
    h = Hash[data.collect{|k, v|
      val = v.collect{|o|
        if o['id'].blank? || o['expires'].blank? || DateTime.strptime(o['expires'],'%Y-%m-%dT%H:%M') < now
          nil
        else
          o
        end
      }.compact
      [k, val]
    }]
    self.data = h
  end

end
