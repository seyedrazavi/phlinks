xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "phlinks"
    xml.description "Links from #philosophy Twitter"
    xml.link root_url

    @links.each do |link|
      xml.item do
        xml.title link.title
        xml.description link.url
        xml.pubDate link.posted_at.to_s(:rfc822)
        xml.link link.url
        xml.guid link.url
      end
    end
  end
end