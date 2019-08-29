class Link < ApplicationRecord

	validates :title, presence: true
	validates :url, presence: true
	validates :posted_at, presence: true
	validates :user, presence: true
	
end
