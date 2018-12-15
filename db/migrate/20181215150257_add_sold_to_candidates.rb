class AddSoldToCandidates < ActiveRecord::Migration[5.0]
  def change
    add_column :candidates, :sold, :boolean, default: false, null: false
  end
end
