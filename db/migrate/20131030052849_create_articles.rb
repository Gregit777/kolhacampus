class CreateArticles < ActiveRecord::Migration
  def up
    create_table :articles do |t|
      t.string      :title,             null: false,    limit: 255
      t.string      :subtitle,          null: false,    limit: 255
      t.string      :image,             null: true,     limit: 255
      t.text        :body
      t.datetime    :publish_at,        null: false
      t.text        :tags,              null: true
      t.column      :status, :tinyint,  null: false,    :default => Status::Pending
      t.string      :old_id,            null: true,     limit: 64
      t.timestamps
    end

    add_index :articles, :old_id, unique: true

    create_join_table :articles, :users do |t|
      t.index :article_id
      t.index :user_id
    end

    create_join_table :articles, :categories do |t|
      t.index :article_id
      t.index :category_id
    end
  end

  def down
    drop_table :articles
    drop_join_table :articles, :users
    drop_join_table :articles, :categories
  end
end
