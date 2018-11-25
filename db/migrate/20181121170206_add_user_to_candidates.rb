class AddUserToCandidates < ActiveRecord::Migration[5.0]
  def change
    add_column :candidates, :user, :string
  end
end
