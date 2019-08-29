require 'open-uri'
class Nokogiri::HTML::Document
  # Use open-uri to get document and set url accordingly.
  def self.get(url)
    raw = open(url)
    parse(raw, raw.base_uri.try(:to_s)) # handles redirected url
  end
end
module Nokogiri::HTML
  def self.get(url)
    Document.get(url)
  end
end