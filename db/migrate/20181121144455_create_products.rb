class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :asin
      t.string :jan
      t.string :title
      t.float :new_price
      t.float :used_price
      t.integer :sales
      t.boolean :self_sale
      t.string :search_result
      t.text :memo
      t.string :label
      t.string :delta_link

      t.timestamps
    end
  end
end
