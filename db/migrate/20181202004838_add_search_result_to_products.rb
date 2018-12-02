class AddSearchResultToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :search_result, :integer
  end
end
