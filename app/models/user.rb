class User < ActiveRecord::Base

  include I18n::Model

  ROLES = %w{author assistant_broadcaster broadcaster assistant_producer producer admin}

  # Devise
  # :token_authenticatable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :omniauthable

  # Associations
  has_and_belongs_to_many :programs
  has_and_belongs_to_many :articles
  has_and_belongs_to_many :events

  # CarrierWave
  mount_uploader :image, DisplayPhotoUploader

  # Scopes
  scope :active, -> { where('active = 1 and status >= ?', Status::Confirmed) }

  def fullname
    [first_name_i18n, last_name_i18n].join(' ')
  end

  def to_s
    self.fullname
  end

  def program_ids
    programs.map(&:id)
  end

  # Role management
  def roles=(roles)
    self.roles_mask = (roles & ROLES).map { |r| 2**ROLES.index(r) }.inject(0, :+)
  end

  def roles
    ROLES.reject do |r|
      ((roles_mask || 0) & 2**ROLES.index(r)).zero?
    end
  end

  def is?(role)
    roles.include?(role.to_s)
  end

  def self.roles_list
    ROLES.map {|r| [r.humanize.capitalize, r]}
  end

  # OmniAuth
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.new(
          first_name: auth.info.first_name,
          last_name: auth.info.last_name,
          provider:auth.provider,
          uid:auth.uid,
          email:auth.info.email,
          roles:[],
          about: auth.extra.raw_info.quotes,
          token: auth.credentials.token,
          active: true
      )
      user.password = Devise.friendly_token[0,20]

      file = Tempfile.new([auth.uid, '.jpeg'], '/tmp', :encoding => 'ascii-8bit')
      file.write open(auth.info.image.gsub(/square/,'large'), 'rb').read
      user.image = file
      begin
        user.save!
      ensure
        file.close
        file.unlink
      end
    end
    user
  end
end
