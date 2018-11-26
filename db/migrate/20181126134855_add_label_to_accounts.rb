class AddLabelToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :label, :string
  end
end
