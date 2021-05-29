class AddIndexToUsersEmpId < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :emp_id, unique:true
  end
end
