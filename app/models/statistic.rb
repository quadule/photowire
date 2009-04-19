class Statistic
  include DataMapper::Resource
  
  property :id, Serial
  property :name, String, :unique => true
  property :value, String
  property :updated_at, DateTime
  
  def self.update_all
    {
      'photo_count' => Photo.downloaded.count,
      'attribute_count' => PhotoExifAttribute.count
    }.each do |name, value|
      first_or_create(:name => name).update_attributes(:value => value)
    end
  end
  
  def self.method_missing(name, *args)
    if record = first(:name => name)
      record.value
    else
      super
    end
  end
end
