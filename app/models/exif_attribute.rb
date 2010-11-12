class ExifAttribute
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  
  validates_uniqueness_of :name
end