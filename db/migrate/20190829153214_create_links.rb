class CreateLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :links do |t|
      t.string :tweet_id
      t.string :title
      t.string :url
      t.datetime :posted_at
      t.string :user_name
      t.string :user_screenname

      t.timestamps
    end
  end
end
