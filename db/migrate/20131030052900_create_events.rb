class CreateEvents < ActiveRecord::Migration
  def up
    create_table :events do |t|
      t.string      :title,             null: false,    limit: 255
      t.string      :subtitle,          null: false,    limit: 255
      t.string      :image,             null: true,     limit: 255
      t.text        :body
      t.datetime    :starts_at,         null: false
      t.datetime    :ends_at,           null: false
      t.string      :location,          null: true
      t.string      :map,               null: true,     limit: 2048
      t.text        :tags,              null: true
      t.column      :status, :tinyint,  null: false,    :default => Status::Pending
      t.string      :old_id,            null: true,     limit: 64
      t.timestamps
    end

    add_index :events, :old_id, unique: true

    create_join_table :events, :users do |t|
      t.index :event_id
      t.index :user_id
    end

    create_join_table :events, :categories do |t|
      t.index :event_id
      t.index :category_id
    end
  end

  def down
    drop_table :events
    drop_join_table :events, :users
    drop_join_table :events, :categories
  end
end
