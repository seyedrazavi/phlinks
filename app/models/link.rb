class Link < ApplicationRecord

	FETCH_COUNT = 200

	validates :title, presence: true
	validates :url, presence: true
	validates :posted_at, presence: true
	validates :user_name, presence: true
	validates :user_screenname, presence: true

	# deleted

	def self.all_but_deleted
		where({deleted: false}).order('created_at ASC')
	end

	def self.fetch_links
		links = []
		last_link = Link.order('created_at ASC').first
		timeline_options = {count: FETCH_COUNT}
		if last_link
			timeline_options[since_id: last_link.tweet_id]
		end

		TWITTER.list_timeline("philosophers", timeline_options).each do |tweet|
			text = tweet.full_text
			logger.debug text
			urls = URI.extract(text)
			urls = urls.select{|uri| uri && (uri.starts_with?("https://") || uri.starts_with?("http://"))}
			urls = urls.map{|url| resolved_url(url)}
			urls = urls.select{|url| url && !url.starts_with?("https://twitter.com")}
			urls.each do |url|
				unless Link.where({url: url}).count > 0
					title = get_title(url)
					posted_at = tweet.created_at
					user_name = tweet.user.name
					user_screenname = tweet.user.screen_name
					logger.info "##{tweet.id} #{title} <#{url}> by #{user_name} <@#{user_screenname}> on #{posted_at}"
					links << {id: tweet.id, url: url, title: title, user_name: user_name, user_screenname: user_screenname, posted_at: posted_at} unless url.nil? || title.nil?
				end
			end
		end
		links
	end
	
	def self.fetch!
		links = fetch_links
		logger.info "Found #{links.count} new links"
		links.each do |link|
			create!(tweet_id: link[:id], title: link[:title], url: link[:url], posted_at: link[:posted_at], user_name: link[:user_name], user_screenname: link[:user_screenname])
		end
	end

	def self.clean_up!
		where("created_at < NOW() - INTERVAL '30 days'").delete_all
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
