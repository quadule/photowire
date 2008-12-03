class ExifAttribute
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :name, String
  
  validates_is_unique :name
end