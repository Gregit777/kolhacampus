class CreateCategories < ActiveRecord::Migration
  def up
    create_table :categories do |t|
      t.string :name,       null: false,  limit: 255
      t.string :bg_color,   null: true,   limit: 255
      t.string :icon,       null: true,   limit: 255
    end

    add_index :categories, :name, unique: true
  end

  def down
    drop_table :categories
  end
end
