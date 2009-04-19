class IgnoredUrl
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :url, String, :length => 255, :unique => true
  property :reason, String
  property :created_at, Time
  property :last_seen_at, Time
  
  def self.ignore?(url)
    if ignored = first(:url => url)
      Merb.logger.info "Saw ignored URL #{url}"
      ignored.last_seen_at = Time.now.utc
      ignored.save!
      true
    else
      false
    end
  end
  
  def self.ignore(url, reason)
    ignored = first_or_create(:url => url)
    ignored.last_seen_at = ignored.created_at = Time.now.utc
    ignored.reason = reason
    ignored.save!
  end
end