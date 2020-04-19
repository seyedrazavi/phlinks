class AddCountsToLink < ActiveRecord::Migration[5.2]
  def change
  	add_column :links, :quote_count, :integer
  	add_column :links, :reply_count, :integer
  	add_column :links, :retweet_count, :integer
  	add_column :links, :favorite_count, :integer
  	add_column :links, :impact, :integer
  end
end
