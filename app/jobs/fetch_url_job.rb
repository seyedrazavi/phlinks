class FetchUrlJob < ApplicationJob
	queue_as :default

	def perform(*args)
		Link.fetch_url!(args[0])
	end
end
