class CreateConfiguration < ActiveRecord::Migration
  def up
    create_table :configuration do |t|
      t.string :name, null: false
      t.text   :data, null: false
    end

    add_index :configuration, :name, unique: true
  end

  def down
    drop_table :configuration
  end
end
