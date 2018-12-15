class AddSearchNumToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :search_num, :integer
  end
end
