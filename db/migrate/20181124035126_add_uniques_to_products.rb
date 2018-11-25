class AddUniquesToProducts < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      ALTER TABLE products
        ADD CONSTRAINT for_upsert UNIQUE ("user", "asin");
    SQL
  end
end
