class Link < ApplicationRecord

	FETCH_COUNT = 200
	MIN_IMPACT_FOR_RETWEET = 5

	validates :title, presence: true
	validates :url, presence: true
	validates :posted_at, presence: true
	validates :user_name, presence: true
	validates :user_screenname, presence: true

	before_save :calculate_impact

	#:quote_count, :integer
  	#:reply_count, :integer
  	#:retweet_count, :integer
  	#:favorite_count, :integer
  	#:impact, :integer

	FILTER_OUT_URLS = ["https://twitter.com", # self-reference
		# low quality
		"https://curiouscat.me",
		# paywalls
		"https://on.ft.com", "https://www.ft.com/", "https://www.wired.com"]

	FILTER_OUT_TITLES = ["Unknown", "redirection forbidden", "HTTP redirection loop",
		"400 Bad Request", "403 Forbidden", "404 Not Found", 
		"416 Requested Range Not Satisfiable", "429 Too Many Requests", 
		"500 Internal Server Error", "502 Bad Gateway",
		"503 Service Unavailable", "Error - Cookies Turned Off",
		"Login • Instagram", "LISTSERV 16.0 - PHILOS-L Archives",
		"Loading seems to be taking a while"]

	# deleted

	#
	# CLass functions
	#

	def self.all_but_deleted
		where({deleted: false}).order('impact DESC, created_at DESC')
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
			deleted: false,
			quote_count: link_hash[:quote_count], reply_count: link_hash[:reply_count], 
			retweet_count: link_hash[:retweet_count], favorite_count: link_hash[:favorite_count]
			)
	end

	# def self.delete_duplicates!
	# 	Link.find_each{|link| Link.where(["url = ? AND id <> ?", link.url, link.id]).delete_all}
	# end

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
			else
				existing_link = Link.where({url: url}).first
				existing_link.quote_count = tweet_hash[:quote_count]
				existing_link.reply_count = tweet_hash[:reply_count]
				existing_link.retweet_count = tweet_hash[:retweet_count]
				existing_link.favorite_count = tweet_hash[:favorite_count]
				existing_link.save
			end
		end
		return false, error
	end

	def self.fetch_tweets
		tweets = []
		last_link = Link.order('created_at DESC').first
		timeline_options = {count: FETCH_COUNT, user: LIST_USER_ID.to_i}
		if last_link
			timeline_options[since_id: last_link.tweet_id]
		end

		TWITTER.list_timeline(LIST_ID.to_i, timeline_options).each do |tweet|
			logger.debug tweet
			tweets << tweet
		end
		tweets
	end

	def self.tweet_to_hash(tweet)
		{id: tweet.id, full_text: tweet.full_text, posted_at: tweet.created_at.to_s, 
		user_name: tweet.user.name, user_screenname: tweet.user.screen_name,
		quote_count: convert_to_int(tweet.quote_count), reply_count: convert_to_int(tweet.reply_count), 
		retweet_count: convert_to_int(tweet.retweet_count), favorite_count: convert_to_int(tweet.favorite_count),
		retweeted: tweet.retweeted_status?}
	end

	def self.clean_up!
		where("created_at < NOW() - INTERVAL '10 days'").delete_all
		logger.info "Deleted older than 10 days"
		#delete_duplicates!
		logger.info "Deleted duplicates"
		logger.info "Updating impact"
		all_but_deleted.where("impact < #{MIN_IMPACT_FOR_RETWEET} AND created_at > NOW() - INTERVAL '2 days'").find_each do |link|
			link.update_impact!
		end
		logger.info "Clean up older links that have low impact"
		where("impact < #{MIN_IMPACT_FOR_RETWEET} AND created_at < NOW() - INTERVAL '2 days'").delete_all
		logger.info "Clean up complete"
	end

	def self.fetch_tweet(id)
		tweet = TWITTER.status(id)
		tweet_to_hash(tweet)
	end

	def self.retweet(id)
		tweet = TWITTER.status(id)
		TWITTER.retweet tweet
	end

	private

	def self.convert_to_int(str)
		begin
			return str.to_i
		rescue
			return 0
		end
	end

	def calculate_impact
		self.impact = (self.quote_count + self.reply_count + self.retweet_count + self.favorite_count)
		if self.impact >= MIN_IMPACT_FOR_RETWEET
			begin
				Link.retweet(self.tweet_id) 
			rescue
			end
		end
	end

	#
	# Member functions
	# 

	public 

	def update_impact!
		begin
			tweet_hash = Link.fetch_tweet(self.tweet_id)
			self.quote_count = tweet_hash[:quote_count]
			self.reply_count = tweet_hash[:reply_count]
			self.retweet_count = tweet_hash[:retweet_count]
			self.favorite_count = tweet_hash[:favorite_count]
			self.save!
		rescue Twitter::Error::NotFound
			logger.info("#{self} no longer available so deleting self")
			self.destroy
		rescue Twitter::Error::Forbidden
			logger.info("#{self} no longer viewable so deleting self")
			self.destroy
		rescue Exception => e
			logger.error("Unable to fetch #{self} because #{e.class}")
		end
	end

	def impact_description
		s = ""
		begin
		s = s + "Quoted: #{self.quote_count}" if self.quote_count > 0
		rescue
		end
		begin
		s = s + "Replies: #{self.reply_count}\n" if self.reply_count > 0
		rescue
		end
		begin
		s = s + "Retweeted: #{self.retweet_count}\n " if self.retweet_count > 0
		rescue
		end
		begin
		s = s + "Favourited: #{self.favorite_count}" if self.favorite_count > 0
		rescue
		end
		s = "No impact yet" if s.blank?
		s
	end

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
