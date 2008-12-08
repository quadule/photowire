%w{hpricot open-uri ruby-debug}.each { |r| require r }

class Wire
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :name, String
  property :url, String
  property :feed_cache, Text
  property :refreshed_at, Time
  
  has n, :photos
  
  def refresh
    self.feed_cache = open(url).read
    self.refreshed_at = Time.now
    @feed = nil
    save!
  end
  
  def feed
    refresh if refreshed_at.nil? || (Time.now.utc - refreshed_at) > 3600 #1 hour
    @feed ||= Hpricot.XML(feed_cache)
  end
  
  def crawl
    (feed/'//item').reverse.each do |item|
      enclosure = (item/'enclosure')[0]
      photo = Photo.new(:url => enclosure[:url], :wire => self)
      photo.expected_size = enclosure[:length].to_i
      
      unless photo.duplicate?
        photo.published_at = Time.parse((item/'pubDate').inner_text)
        photo.save!
        photo.thumbnail if photo.download
      end
    end
  end
end
