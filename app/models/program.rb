class Program < ActiveRecord::Base

  include I18n::Model

  # Associations
  has_and_belongs_to_many :users
  has_many :tracklists

  # CarrierWave
  mount_uploader :image, DisplayPhotoUploader

  # Acts as taggable
  acts_as_taggable

  # Scopes
  scope :active, -> { where('active = 1 and status >= ?', Status::Confirmed).includes(:users) }
  scope :in_library, -> {
    where('programs.active = 1 and programs.status >= ?', Status::Confirmed)
    .joins(:tracklists).where.not('tracklists.ondemand_url' => nil, 'tracklists.tracks' => nil, 'tracklists.tracks' => "{}")
    .includes(:users).uniq
  }
  def user_ids
    users.map(&:id)
  end

end
