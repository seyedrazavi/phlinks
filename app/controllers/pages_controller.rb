class PagesController < ApplicationController
  def home
  	@links = Link.all_but_deleted
  end
end
