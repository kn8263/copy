class AddUserInfoToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :emp_id, :integer
    add_column :users, :hour_pay, :integer
    add_column :users, :dep_id, :integer
    add_column :users, :bikou, :string
    add_column :users, :tp_ex, :integer
    add_column :users, :position, :string
  end
end
