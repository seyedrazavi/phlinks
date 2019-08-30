class PagesController < ApplicationController
  def home
  	@links = Link.all_but_deleted
    respond_to do |format|
      format.html
      format.rss { render :layout => false }
    end
  end
end
