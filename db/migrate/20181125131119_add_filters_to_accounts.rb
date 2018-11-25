class AddFiltersToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :condition, :string
    add_column :accounts, :attachment, :string
    add_column :accounts, :new_price_diff, :integer
    add_column :accounts, :used_price_diff, :integer
  end
end
