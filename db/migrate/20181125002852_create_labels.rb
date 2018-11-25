class CreateLabels < ActiveRecord::Migration[5.0]
  def change
    create_table :labels do |t|
      t.string :user
      t.integer :number
      t.string :caption

      t.timestamps
    end
  end
end
