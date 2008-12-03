class Photo
  include DataMapper::Resource
  is_paginated
  property :id, Integer, :serial => true
  property :published_at, Time
  property :downloaded_at, Time
  property :url, String, :length => 255
  property :path, String, :length => 255
  property :size, Integer
  property :description, DataMapper::Types::Text
  
  belongs_to :wire, :class_name => 'Wire'
  has n, :exif_attributes, :class_name => 'PhotoExifAttribute'
  
  validates_is_unique :url, :path
  
  attr_reader :exif
  
  def self.downloaded
    all :downloaded_at.not => nil
  end
  
  def self.failed
    all :downloaded_at => nil
  end
  
  IGNORE_ATTRIBUTES = %w{
    APP14Flags0 APP14Flags1 ApplicationRecordVersion BitsPerSample CMMFlags
    ColorSpaceData ComponentsConfiguration ComponentsConfiguration Compression
    DateCreated DCTEncodeVersion DeviceAttributes Directory EncodingProcess
    ExifByteOrder ExifImageHeight ExifImageWidth ExifToolVersion ExifVersion
    FNumber FileModifyDate FileName FileSize FileType FlashpixVersion
    FocalLength35efl FocalLengthIn35mmFormat GPSVersionID ImageDescription
    ImageSize InteropIndex InteropVersion JFIFVersion MediaBlackPoint MIMEType
    ProfileClass ProfileCopyright ProfileCreator ProfileDateTime
    SubSecDateTimeOriginal SubSecTimeDigitized SubSecTimeOriginal
    ThumbnailLength ThumbnailOffset TimeCreated
  }
  IGNORE_VALUES = %w{Normal (none) none None Unknown Uncalibrated}
  
  after :path=, :set_file_size
  
  def set_file_size
    self.size = File.size(path) unless path.nil?
  end
  
  def thumbnail
    thumb_path = path.sub(/(\.jpg)$/i, '.thumb.jpg')
    return thumb_path if File.exists?(thumb_path)
    
    img = Magick::Image.read(path).first
    bigger_dimension = img.rows > img.columns ? img.rows : img.columns
    scale = 150.0/bigger_dimension
    img.thumbnail!(scale)
    
    img.write(thumb_path) {
      self.format = 'JPG'
      self.quality = 90
    }
    img.destroy!
    
    thumb_path
  end
  
  def description_trimmed
    (description || '').
      gsub(/^\*\* .* \*\* /, '').         #remove note
      gsub(/ ?\(AP Photo\/?.*\)\.?$/, '') #remove credit
  end
  
  def duplicate?
    !!self.class.first(:path.like => "%-#{url_number}.jpg")
  end
  
  def url_number
    url[/(\d+)\.jpg$/i, 1]
  end
  
  def alternate_url
    #http://flickrfan.files.wordpress.com/2008/10/ap13787.jpg
    #http://static.flickrfan.org/ap2/2008/11/06/14664.jpg
    case url
    when %r{^http://flickrfan\.files\.wordpress\.com/}i
      "http://static.flickrfan.org/ap2/#{published_at.strftime('%Y/%m/%d')}/#{url_number}.jpg"
    when %r{^http://static\.flickrfan\.org/}i
      "http://flickrfan.files.wordpress.com/#{published_at.strftime('%Y/%m')}/ap#{url_number}.jpg"
    else
      nil
    end
  end
  
  def download
    urls = [alternate_url, url]
    data = nil
    while data.nil? and urls.length > 0
      begin
        url = urls.pop
        puts "downloading #{url}"
        data = open(url).read
      rescue Exception => ex
        puts ex
      end
    end
    
    if success = !!(data && data.length > 1024)
      Tempfile.open('photowire') do |tmp|
        tmp.binmode.write(data)
        self.path = tmp.path
        parse_exif
        
        dir = Merb.root / 'public' / 'images' / published_at.strftime('%Y/%m/%d')
        FileUtils.mkpath(dir) unless File.directory?(dir)
        destination = dir / "#{published_at.strftime('%Y%m%d')}-#{url_number}.jpg"
        File.rename(tmp.path, destination)
        self.path = destination.sub(Merb.root + '/', '')
        self.downloaded_at = Time.now
      end
      save!
    end
    success
  end
  
  def attributes_hash
    hash = {}
    exif_attributes.each { |a| hash[a.exif_attribute.name] = a.value }
    hash
  end
  
  def fix
    @exif = MiniExiftool.new(Merb.root / path).to_hash
    if @exif["Country-PrimaryLocationName"]
      self.exif_attributes.create(
        :exif_attribute => ExifAttribute.first_or_create(:name => "Country-PrimaryLocationName"),
        :value => @exif["Country-PrimaryLocationName"]
      )
      @exif["Country-PrimaryLocationName"]
    end
  end
  
  def parse_exif
    @exif = MiniExiftool.new(path).to_hash
    description = @exif.delete("Caption-Abstract")
    self.description = description.join(' ') if description.is_a?(Array)
    self.published_at = @exif['DateTimeOriginal']
    self.published_at = self.published_at.gsub(/^(\d{4}):(\d{2}):(\d{2}) /, '\1/\2/\3 ') if published_at.is_a?(String)
    self.downloaded_at ||= @exif['FileModifyDate']
    
    self.exif_attributes.each { |a| a.destroy }
    @exif.each do |key, value|
      next if value.blank? || IGNORE_ATTRIBUTES.include?(key) || IGNORE_VALUES.include?(value)
      
      if value.is_a?(Array)
        next if value[0].include?('(Binary data')
        value = value.join(' ')
      end
      
      self.exif_attributes.create(
        :exif_attribute => ExifAttribute.first_or_create(:name => key),
        :value => value
      )
    end
    @exif
  end
end
