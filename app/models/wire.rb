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
    refresh if (Time.now.utc - refreshed_at) > 3600 #1 hour
    @feed ||= Hpricot.XML(feed_cache)
  end
  
  def crawl
    (feed/'//item').reverse.each do |item|
      photo = Photo.new(:url => (item/'enclosure')[0][:url], :wire => self)
      unless photo.duplicate?
        begin
          photo.published_at = Time.parse((item/'pubDate').inner_text)
          photo.save!
          if photo.download
            puts "thumbnailing"
            photo.thumbnail
          else
            puts "error downloading!"
          end
        rescue Exception => ex
          debugger
          x=1
        end
      end
    end
  end
end
