class AddUniquesToCandidates < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      ALTER TABLE candidates
        ADD CONSTRAINT for_upsert_candidate UNIQUE ("user", "asin", "item_id");
    SQL
  end
end
