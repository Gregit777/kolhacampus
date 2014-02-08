class CreateRawTracklists < ActiveRecord::Migration
  def up
    create_table :raw_tracklists do |t|
      t.string    :source,    :null => false
      t.text      :results,   :null => true
      t.datetime  :last_run,  :null => true
    end
  end

  def down
    drop_table :raw_tracklists
  end
end
