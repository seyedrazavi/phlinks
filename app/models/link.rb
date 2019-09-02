class Link < ApplicationRecord

	FETCH_COUNT = 200

	validates :title, presence: true
	validates :url, presence: true
	validates :posted_at, presence: true
	validates :user_name, presence: true
	validates :user_screenname, presence: true

	FILTER_OUT_URLS = ["https://twitter.com", # self-reference
		# low quality
		"https://curiouscat.me",
		# paywalls
		"https://on.ft.com", "https://www.ft.com/", "https://www.wired.com"]

	FILTER_OUT_TITLES = ["Unknown", "redirection forbidden", "403 Forbidden", "404 Not Found", 
		"416 Requested Range Not Satisfiable", "429 Too Many Requests", "503 Service Unavailable",
		"LISTSERV 16.0 - PHILOS-L Archives"]

	# deleted

	#
	# CLass functions
	#

	def self.all_but_deleted
		where({deleted: false}).order('created_at DESC')
	end

	def self.fetch!(async=true)
		tweets = fetch_tweets
		tweets.each do |tweet|
			if async
				FetchUrlJob.perform_later (tweet_to_hash(tweet))
			else
				Link.fetch_url!(tweet_to_hash(tweet))
			end
		end
		logger.info "Found #{tweets.count} tweets"
	end

	def self.create_link!(link_hash)
		create!(tweet_id: link_hash[:id], title: link_hash[:title], url: link_hash[:url], 
			posted_at: link_hash[:posted_at], user_name: link_hash[:user_name], 
			user_screenname: link_hash[:user_screenname], description: link_hash[:full_text],
			deleted: false)
	end


	private
	
	def self.fetch_url!(tweet_hash)
		parsed_tweet = parse_tweet(tweet_hash)
		if parsed_tweet[0]
			logger.info "Creating #{parsed_tweet[0]}..."
			link = create_link!(parsed_tweet[1]) 
			logger.info "done"
		else
			logger.debug "#{tweet_hash}: #{parsed_tweet[1]}"
		end
	end

	def self.parse_tweet(tweet_hash)
		error = nil
		text = tweet_hash[:full_text]
		logger.debug text
		urls = URI.	extract(text)
		urls = urls.select{|uri| uri && (uri.starts_with?("https://") || uri.starts_with?("http://"))}
		return false, "No URLs in tweet" unless urls.count > 0
		urls = urls.map{|url| resolved_url(url)}
		return false, "URLs in tweet could not be resolved" unless urls.count > 0
		urls = urls.select{|url| url && !FILTER_OUT_URLS.any?{|f| url.starts_with?(f)}}
		return false, "URLs in tweet where filted out" unless urls.count > 0
		urls.each do |url|
			unless Link.where({url: url}).count > 0
				title = get_title(url)
				if title.blank?
					error = "Page title is blank" 
				elsif FILTER_OUT_TITLES.any?{|f| title.starts_with?(f)}
					error = "Page title was filtered out"
				else
					return true, tweet_hash.merge({url: url, title: title})
				end
			end
		end
		return false, error
	end

	def self.fetch_tweets
		tweets = []
		last_link = Link.order('created_at DESC').first
		timeline_options = {count: FETCH_COUNT}
		if last_link
			timeline_options[since_id: last_link.tweet_id]
		end

		TWITTER.list_timeline("philosophers", timeline_options).each do |tweet|
			logger.debug tweet
			tweets << tweet
		end
		tweets
	end

	def self.tweet_to_hash(tweet)
		{id: tweet.id, full_text: tweet.full_text, posted_at: tweet.created_at.to_s, 
				user_name: tweet.user.name, user_screenname: tweet.user.screen_name}
	end

	def self.clean_up!
		where("created_at < NOW() - INTERVAL '30 days'").delete_all
	end

	#
	# Member functions
	# 

	public 

	def update_title!
		new_url = Link.resolved_url(self.url)
		self.url = new_url unless new_url.nil?
		new_title = Link.get_title(self.url)
		self.title = new_title unless new_title.nil?
		save!
	end

	def soft_delete!
		self.deleted = true
		save!
	end

	def soft_undelete!
		self.deleted = false
		save!
	end

	def self.resolved_url(url)
		uri = URI.parse(url)
		tries = 3

		begin
		  uri.open(redirect: false)
		rescue OpenURI::HTTPRedirect => redirect
		  uri = redirect.uri # assigned from the "Location" response header
		rescue OpenURI::HTTPError => e
			return nil
		end
		uri.to_s
	end

	def self.get_title(url)
		title = nil
		begin
			doc = Pismo::Document.new(url)
			title = doc.title
			title = "Unknown" if title.blank? 
			logger.debug "get_title: #{url} > #{doc.title}"
		rescue OpenURI::HTTPError => e
			title = e.to_s
			logger.warn "get_title url: #{url} - #{e}" 
		rescue RuntimeError => e
			title = e.to_s
			logger.error "get_title url: #{url} - #{e}"  
		end
		title
	end
end
