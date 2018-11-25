class AddItemIdToCandidates < ActiveRecord::Migration[5.0]
  def change
    add_column :candidates, :item_id, :string
  end
end
