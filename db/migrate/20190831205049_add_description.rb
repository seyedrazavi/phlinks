class AddDescription < ActiveRecord::Migration[5.2]
  def change
  	add_column :links, :description, :text
  end
end
