class AddFilterOptionsToProducts < ActiveRecord::Migration[5.0]
  def change
    change_column :products, :filtered, :boolean, default: false, null: false
  end
end
