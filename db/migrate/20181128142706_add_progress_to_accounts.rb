class AddProgressToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :progress, :integer
  end
end
