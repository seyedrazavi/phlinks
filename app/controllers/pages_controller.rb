class PagesController < ApplicationController
  def home
  	@links = Link.all_but_deleted
  	@admin_mode = params[:admin]
    respond_to do |format|
      format.html
      format.rss { render :layout => false }
    end
  end

  def about
  end
end
