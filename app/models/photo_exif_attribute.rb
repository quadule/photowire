class PhotoExifAttribute
  include DataMapper::Resource
  property :id, Integer, :serial => true
  property :value, String
  
  belongs_to :exif_attribute
  belongs_to :photo
  
  IGNORE_KEYS = %w{
    APP14Flags0 APP14Flags1 ApplicationRecordVersion BitsPerSample CMMFlags
    ColorMode ColorSpaceData ComponentsConfiguration ComponentsConfiguration
    Compression DateCreated DCTEncodeVersion DeviceAttributes Directory
    EncodingProcess EnvelopeRecordVersion ExifByteOrder ExifImageHeight
    ExifImageWidth ExifToolVersion ExifVersion FileFormat FileModifyDate
    FileName FileSize FileType FileVersion FlashpixVersion FNumber
    FocalLength35efl FocalLengthIn35mmFormat Format GPSVersionID
    ImageDescription ImageHeight ImageSize ImageWidth InteropIndex
    InteropVersion JFIFVersion MediaBlackPoint MIMEType ProductID ProfileClass
    ProfileConnectionSpace ProfileCopyright ProfileCreator ProfileDateTime
    ProfileFileSignature ProfileID Rotation ServiceIdentifier
    SubSecDateTimeOriginal SubSecTimeDigitized SubSecTimeOriginal
    ThumbnailLength ThumbnailOffset TimeCreated
  }
  IGNORE_VALUES = %w{Normal (none) none None Unknown Uncalibrated}
  
  def self.ignore?(key, value)
    IGNORE_KEYS.include?(key) || IGNORE_VALUES.include?(value) || binary?(value)
  end
  
  def self.binary?(value)
    !!(value =~ /^\(Binary data \d+ bytes, use -b option to extract\)/)
  end
  
  def self.cleanup
    all('exif_attribute.name' => IGNORE_KEYS).each { |a| a.destroy }
  end
end
