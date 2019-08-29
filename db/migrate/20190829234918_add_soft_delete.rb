class AddSoftDelete < ActiveRecord::Migration[5.2]
  def change
  	add_column :links, :deleted, :boolean
  	Link.update_all(deleted: false)  
  end
end
