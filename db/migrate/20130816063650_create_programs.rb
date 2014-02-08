class CreatePrograms < ActiveRecord::Migration
  def up
    create_table :programs, :force => true do |t|
      t.string  :name,              :null => false,     :limit => 255
      t.string  :name_en,           :null => true,      :limit => 255
      t.text    :description,       :null => true
      t.string  :image,             :null => true,      :limit => 255
      t.boolean :active,            :null => true,      :default => false
      t.boolean :live,              :null => true,      :default => false
      t.column  :status, :tinyint,  :null => false,     :default => Status::Pending
      t.integer :icast_program_id,  :null => true
      t.boolean :is_set,            :null => false,     :default => false
      t.integer :tracklist_count,   :null => false,     :default => 0
      t.timestamps
    end

    add_index :programs, :icast_program_id, :unique => true
    add_index :programs, :status,           :unique => false

    create_table :programs_users, :force => true, :id => false do |t|
      t.integer :program_id,  :null => false
      t.integer :user_id,     :null => false
    end

    add_index :programs_users, [:program_id, :user_id], :unique => true
    add_index :programs_users, [:user_id, :program_id], :unique => true

  end

  def down
    drop_table :programs_users
    drop_table :programs
  end
end
