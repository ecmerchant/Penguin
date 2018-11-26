class AddFilteredToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :filtered, :boolean
  end
end
