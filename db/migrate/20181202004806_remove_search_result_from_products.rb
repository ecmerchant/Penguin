class RemoveSearchResultFromProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :search_result, :string
  end
end
