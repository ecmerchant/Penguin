class AddFilteredToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :filtered, :boolean, default: false, null: false
  end
end
