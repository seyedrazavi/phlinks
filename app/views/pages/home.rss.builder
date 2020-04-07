xml.instruct! :xml, :version => "1.0"
xml.rss "version" => "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title "phlinks"
    xml.description "Links from #philosophy Twitter"
    xml.link root_url
    xml.tag!("atom:link", "href" => root_url(:format => :rss), "rel" => "self", "type" => "application/rss+xml")

    @links.limit(100).each do |link|
      xml.item do
        xml.title link.title
        xml.pubDate link.posted_at.to_s(:rfc822)
        xml.description link.description
        xml.link link.url
        xml.guid link.url
      end
    end
  end
end