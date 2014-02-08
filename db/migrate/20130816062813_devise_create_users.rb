class DeviseCreateUsers < ActiveRecord::Migration
  def migrate(direction)
    super

    # Create a default user
    if direction == :up
      u = User.new(:first_name => 'Admin', :last_name => 'Example', :email => 'admin@example.com', :status => Status::Confirmed)
      u.password = u.password_confirmation = 'password'
      u.roles = ['admin']
      u.save
    end
  end

  def change
    create_table(:users) do |t|
      t.string :first_name,         :null => false,     :limit => 255
      t.string :last_name,          :null => false,     :limit => 255
      t.string :first_name_en,      :null => true,      :limit => 255
      t.string :last_name_en,       :null => true,      :limit => 255
      t.string :email,              :null => false,     :limit => 255, :default => ""

      t.column  :about, :mediumtext,:null => true
      t.string :image,              :null => true,      :limit => 255

      t.column  :status, :tinyint,  :null => false,     :default => Status::Pending
      t.boolean :active,            :null => false,     :default => false
      t.string  :token,             :null => true,      :limit => 255

      ## CanCan
      t.integer :roles_mask,        :null => false,     :default => 0

      ## Database authenticatable
      t.string :encrypted_password, :null => false,     :limit => 255, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip,               :limit => 16
      t.string   :last_sign_in_ip,                  :limit => 16

      ## Confirmable
      # t.string   :confirmation_token
      # t.datetime :confirmed_at
      # t.datetime :confirmation_sent_at
      # t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## Token authenticatable
      #t.string :authentication_token,    :limit => 255


      t.timestamps
    end

    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    # add_index :users, :confirmation_token,   :unique => true
    # add_index :users, :unlock_token,         :unique => true
    # add_index :users, :authentication_token, :unique => true
  end
end
