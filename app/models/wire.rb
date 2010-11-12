%w{hpricot open-uri ruby-debug}.each { |r| require r }

class Wire
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :url, String
  property :feed_cache, Text
  property :refreshed_at, Time
  
  has n, :photos
  
  def refresh
    self.feed_cache = open(url).read
    self.refreshed_at = Time.now.utc
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
      photo.published_at = Time.parse((item/'pubDate').inner_text)
      
      unless photo.expected_size < 10000 || photo.duplicate? || IgnoredUrl.ignore?(enclosure[:url])
        photo.save!
        if photo.download
          if photo.keep?
            photo.thumbnail
          else
            photo.destroy
          end
        end
      end
    end
  end
end
