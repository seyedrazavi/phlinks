class PocketController < ApplicationController
	before_action :set_access_token, only: [:add]

	def add
		@url = params[:url]
		@title = params[:title]
		if @access_token
			save_to_pocket(@access_token, @url, @title)
			redirect_to root_url
		else
			session[:link_url] = @url
			session[:link_title] = @title
			pocket_connect
		end
	end

	def callback
		puts "OAUTH CALLBACK"
		puts "request.url: #{request.url}"
		puts "request.body: #{request.body.read}"
		begin
			result = Pocket.get_result(session[:code], :redirect_uri => callback_url)
			puts "access_token: #{result['access_token']}"
			puts "username: #{result['username']}"
			session[:access_token] = result['access_token']
			if session[:link_url]
				save_to_pocket(session[:access_token], session[:link_url], session[:link_title])
			end
		rescue
			flash[:error] = "Could not connect to Pocket"
		end
		redirect_to root_url
	end

	private
	def pocket_connect
		puts "OAUTH CONNECT"
		session[:code] = Pocket.get_code(:redirect_uri => callback_url)
		new_url = Pocket.authorize_url(:code => session[:code], :redirect_uri => callback_url)
		puts "new_url: #{new_url}"
 		puts "session: #{session}"
		redirect_to new_url
	end

	def save_to_pocket(access_token, url, title)
		puts "SAVE TO POCKET"
		client = Pocket.client(:access_token => access_token)
		info = client.add :url => url
		puts info
		flash[:notice] = "Saved \"<a href=\"#{url}\" target=\"_new\">#{title}</a>\" to Pocket"
	end

	def set_access_token
		@access_token ||= session[:access_token]
	end

	def callback_url
		full_domain_path = request.env['rack.url_scheme'] + '://' + request.host_with_port + '/oauth/callback'
	end
end
