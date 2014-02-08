class CreateTracklists < ActiveRecord::Migration
  def up
    create_table :tracklists do |t|
      t.column    :program_id,      :integer,         :null => false,   :limit => 11
      t.column    :description,     :tinytext,        :null => true
      t.column    :description_en,  :tinytext,        null: true
      t.column    :publish_at,      :datetime,        :null => false
      t.column    :tracks,          :longtext,        :null => true
      t.column    :feed,            :longtext,        :null => true
      t.column    :ondemand_url,    :string,          :null => true,    :limit => 255
      t.column    :status,          :tinyint,         :null => false,   :default => Status::Pending
      t.column    :token,           :string,          :null => true,    :limit => 64
      t.timestamps
    end

    add_index :tracklists, [:program_id,:publish_at], :unique => false
    add_index :tracklists, [:publish_at,:program_id], :unique => false
  end

  def down
    drop_table :tracklists
  end
end
