class AddFilteredToCandidates < ActiveRecord::Migration[5.0]
  def change
    add_column :candidates, :filtered, :boolean
  end
end
