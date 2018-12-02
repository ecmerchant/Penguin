class AddFilterOptionsToCandidates < ActiveRecord::Migration[5.0]
  def change
    change_column :candidates, :filtered, :boolean, default: false, null: false
  end
end
