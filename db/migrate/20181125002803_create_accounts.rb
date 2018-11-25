class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :user
      t.string :shop_url
      t.time :patrol_time

      t.timestamps
    end
  end
end
