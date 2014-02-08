class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules, :force => true do |t|
      t.string    :title,             :null => false, :limit => 255
      t.string    :description,       :null => true,  :limit => 1024
      t.text      :configuration,     :null => false
      t.datetime  :start_date,        :null => true
      t.datetime  :end_date,          :null => true
      t.boolean   :is_default,        :null => false, :default => false
    end
  end
end
