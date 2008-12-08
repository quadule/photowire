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
  property :width, Integer
  property :height, Integer
  
  belongs_to :wire, :class_name => 'Wire'
  has n, :exif_attributes, :class_name => 'PhotoExifAttribute'
  
  validates_is_unique :url, :path
  
  attr_reader :exif
  attr_accessor :expected_size
  
  def self.downloaded
    all :downloaded_at.not => nil
  end
  
  def self.failed
    all :downloaded_at => nil
  end
  
  def self.newest
    downloaded.first :order => [:id.desc]
  end
  
  IGNORE_ATTRIBUTES = %w{
    APP14Flags0 APP14Flags1 ApplicationRecordVersion BitsPerSample CMMFlags
    ColorSpaceData ComponentsConfiguration ComponentsConfiguration Compression
    DateCreated DCTEncodeVersion DeviceAttributes Directory EncodingProcess
    ExifByteOrder ExifImageHeight ExifImageWidth ExifToolVersion ExifVersion
    FNumber FileModifyDate FileName FileSize FileType FlashpixVersion
    FocalLength35efl FocalLengthIn35mmFormat GPSVersionID ImageDescription
    ImageHeight ImageSize ImageWidth InteropIndex InteropVersion JFIFVersion
    MediaBlackPoint MIMEType ProfileClass ProfileCopyright ProfileCreator
    ProfileDateTime SubSecDateTimeOriginal SubSecTimeDigitized
    SubSecTimeOriginal ThumbnailLength ThumbnailOffset TimeCreated
  }
  IGNORE_VALUES = %w{Normal (none) none None Unknown Uncalibrated}
  
  after :path=, :set_file_size
  
  def set_file_size
    self.size = File.size(path) unless path.nil?
  end
  
  def thumbnail
    thumb_path = path.sub(/(\.jpg)$/i, '.thumb.jpg')
    return thumb_path if File.exists?(thumb_path)
    
    Merb.logger.info "Generating thumbnail for Photo[#{id}]"
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
      gsub(/^\*\*.*\*\*\W*/, '').
      gsub(/ ?\(AP Photo\/?.*\)\.?$/, '').
      gsub(/\W*AFP PHOTO.*$/, '')
  end
  
  def duplicate?
    !!self.class.first(:path.like => "%-#{file_identifier}.jpg")
  end
  
  def file_identifier
    url[/\/([^\/]+)\.jpg$/i, 1].sub(/^af?p/i, '')
  end
  
  def alternate_url
    return nil unless wire.name == "Associated Press"
    case url
    when %r{^http://flickrfan\.files\.wordpress\.com/}i
      "http://static.flickrfan.org/ap2/#{published_at.strftime('%Y/%m/%d')}/#{file_identifier}.jpg"
    when %r{^http://static\.flickrfan\.org/}i
      "http://flickrfan.files.wordpress.com/#{published_at.strftime('%Y/%m')}/ap#{file_identifier}.jpg"
    else
      nil
    end
  end
  
  def download
    urls = [alternate_url, url].compact
    data = nil
    while data.nil? and urls.length > 0
      begin
        url = urls.pop
        Merb.logger.info "Downloading Photo[#{id}] from #{url}"
        data = open(url).read
      rescue
        self.description = $!.to_s
        Merb.logger.warn "Download failed for Photo[#{id}] from #{url}: #{$!}"
      end
    end
    
    if data_valid?(data)
      Tempfile.open('photowire') do |tmp|
        tmp.write(data)
        self.path = tmp.path
        
        begin
          parse_exif
        rescue
          Merb.logger.warn "EXIF parsing failed for Photo[#{id}]: #{$!}"
        end
        
        dir = Merb.root / 'public' / 'images' / published_at.strftime('%Y/%m/%d')
        FileUtils.mkpath(dir) unless File.directory?(dir)
        destination = dir / "#{published_at.strftime('%Y%m%d')}-#{file_identifier}.jpg"
        File.rename(tmp.path, destination)
        self.path = destination.sub(Merb.root + '/', '')
        self.downloaded_at = Time.now
      end
      save!
    end
  end
  
  def downloaded?
    !downloaded_at.nil?
  end
  
  def attributes_hash
    hash = {}
    exif_attributes.each { |a| hash[a.exif_attribute.name] = a.value }
    hash
  end
  
  def parse_exif
    @exif = MiniExiftool.new(path).to_hash
    Merb.logger.info "Parsed #{@exif.size} EXIF attributes for Photo[#{id}]"
    description = @exif.delete("Caption-Abstract")
    self.description = description.join(' ') if description.is_a?(Array)
    self.published_at = @exif['DateTimeOriginal']
    self.published_at = self.published_at.gsub(/^(\d{4}):(\d{2}):(\d{2}) /, '\1/\2/\3 ') if published_at.is_a?(String)
    self.downloaded_at ||= @exif['FileModifyDate']
    self.width = @exif['ImageWidth'].to_i
    self.height = @exif['ImageHeight'].to_i
    
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
    Merb.logger.info "Saved #{exif_attributes.size} EXIF attributes for Photo[#{id}]"
    @exif
  end
  
  private
    def data_valid?(data)
      return false if data.nil?
      
      if expected_size && data.length != expected_size
        Merb.logger.warn "Downloaded data for Photo[#{id}] was #{data.length} bytes, expected #{expected_size} bytes"
        return false
      elsif data.length < 1024
        Merb.logger.warn "Downloaded data for Photo[#{id}] was too small"
        return false
      end

      true
    end
end
