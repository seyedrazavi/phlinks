class AddOrderScoreToLinks < ActiveRecord::Migration[5.2]
  def change
  	add_column :links, :order_score, :float
  end
end
