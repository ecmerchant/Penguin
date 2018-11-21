class CreateCandidates < ActiveRecord::Migration[5.0]
  def change
    create_table :candidates do |t|
      t.string :title
      t.float :price
      t.string :condition
      t.text :attachment
      t.text :memo
      t.string :asin
      t.string :jan
      t.float :diff_new_price
      t.float :diff_used_price
      t.string :url

      t.timestamps
    end
  end
end
