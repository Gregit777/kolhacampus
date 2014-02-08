class Category < ActiveRecord::Base

  has_and_belongs_to_many :articles
  has_and_belongs_to_many :events

  scope :for_navigation, -> (ids) { where('id in (?)', ids).select('id', 'name') }
end
