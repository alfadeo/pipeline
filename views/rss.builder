xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Alfadeo links"
    xml.description "The latest news"
    xml.link "http://pipeline.alfadeo.de/rss.xml"

    @links.each_with_index do |link,idx|
      xml.item do
        - title = (!link.info.blank? ? link.info : link.uri)
        xml.title title
        xml.link link.uri
        xml.guid idx
        xml.pubDate Time.parse(link.created_at.to_s).rfc822
      end
    end
  end
end
