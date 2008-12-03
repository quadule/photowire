class PhotoExifAttribute
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :value, String
  
  belongs_to :exif_attribute
  belongs_to :photo
  
  validates_is_unique :exif_attribute_id, :scope => :photo_id
end
