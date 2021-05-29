class AddAggregateInfoToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :day_total_working, :float
    add_column :attendances, :day_regular_working, :float
    add_column :attendances, :day_over_working, :float
    add_column :attendances, :day_night_working, :float
  end
end
