class Photo
  include DataMapper::Resource
  is_paginated
  property :id, Integer, :serial => true
  property :published_at, Time
  property :downloaded_at, Time
  property :url, String, :length => 255
  property :path, String, :length => 255, :unique => true
  property :size, Integer
  property :description, DataMapper::Types::Text
  property :width, Integer
  property :height, Integer
  property :md5, String, :length => 32
  
  belongs_to :wire
  has n, :exif_attributes, :class_name => 'PhotoExifAttribute'
  
  validates_is_unique :url, :allow_nil => true
  
  attr_reader :exif
  attr_accessor :expected_size
  
  before :destroy, :destroy_exif_attributes
  before :destroy, :delete_files
  
  def self.downloaded
    all :downloaded_at.not => nil
  end
  
  def self.failed
    all :downloaded_at => nil
  end
  
  def self.newest
    downloaded.first :order => [:id.desc]
  end
  
  def set_file_size
    self.size = File.size(path)
  end
  
  def set_hash
    self.md5 = `openssl md5 < "#{path}"`.chomp
  end
  
  def destroy_exif_attributes
    exif_attributes.each { |a| a.destroy }
  end
  
  def thumbnail_size
    bigger_dimension = height > width ? height : width
    scale = 150.0/bigger_dimension
    [width, height].map { |dim| (dim * scale).round }
  end
  
  def thumbnail_path
    path.sub(/(\.jpg)$/i, '.thumb.jpg')
  end
  
  def thumbnail
    thumb_path = thumbnail_path
    return thumb_path if File.exists?(thumb_path)
    
    Merb.logger.info "Generating thumbnail for Photo[#{id}]"
    img = Magick::Image.read(path).first
    img.thumbnail!(*thumbnail_size)
    
    img.write(thumb_path) {
      self.format = 'JPG'
      self.quality = 90
    }
    img.destroy!
    File.chmod(0644, thumb_path)
    
    thumb_path
  end
  
  def description_trimmed
    (description || '').
      gsub(/^\*\*.*\*\* */, '').
      gsub(/ ?\(AP Photo\/?.*\)\.?$/, '').
      gsub(/ *AFP[ -]+Photo.*$/i, '').
      gsub(/\(FILES\) */, '').
      gsub(/TO GO WITH( FRENCH)? AFP (STORY|PHOTO) (by|BY) [A-Z ]+ *-*\.* */, '').
      gsub(/^TO GO WITH [A-Z'" -]*\.*:* */, '')
  end
  
  def duplicate?
    return true if self.class.first(:path.like => "%-#{file_identifier}.jpg")
    false
  end
  
  def file_identifier
    url[/\/([^\/]+)\.jpg$/i, 1].sub(/^af?p/i, '')
  end
  
  # in the AFP wire, the filename prefix appears to specify a global region of interest
  def afp_grouping
    return nil unless wire_id == 2
    file_identifier.sub(/\d+/, '')
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
          save_exif
        rescue
          Merb.logger.warn "EXIF parsing failed for Photo[#{id}]: #{$!}"
        end
        
        dir = Merb.root / 'public' / 'images' / published_at.strftime('%Y/%m/%d')
        FileUtils.mkpath(dir) unless File.directory?(dir)
        destination = dir / "#{published_at.strftime('%Y%m%d')}-#{file_identifier}.jpg"
        FileUtils.mv(tmp.path, destination)
        File.chmod(0644, destination)
        self.path = destination.sub(Merb.root + '/', '')
        self.downloaded_at = Time.now
        set_file_size
        set_hash
      end
      save!
    end
  end
  
  def downloaded?
    !downloaded_at.nil?
  end
  
  def delete_files
    if path
      File.delete(thumbnail) if File.exists?(thumbnail_path)
      File.delete(path)
    else
      Merb.logger.warn "Tried to delete undownloaded file for Photo[#{id}]: #{$!}"
    end
  end
  
  def attributes_hash
    hash = {}
    exif_attributes.each { |a| hash[a.exif_attribute.name] = a.value }
    hash
  end
  
  def exif
    @exif ||= MiniExiftool.new(path).to_hash
  end
  
  def save_exif
    Merb.logger.info "Parsed #{exif.size} EXIF attributes for Photo[#{id}]"
    self.description = exif.delete("Caption-Abstract")
    self.description = description.join(' ') if description.is_a?(Array)
    self.published_at = exif['DateTimeOriginal']
    self.published_at = self.published_at.gsub(/^(\d{4}):(\d{2}):(\d{2}) /, '\1/\2/\3 ') if published_at.is_a?(String)
    self.downloaded_at ||= exif['FileModifyDate']
    self.width = exif['ImageWidth'].to_i
    self.height = exif['ImageHeight'].to_i
    
    destroy_exif_attributes
    exif.each do |key, value|
      next if value.blank? || PhotoExifAttribute.ignore?(key, value)
      
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
  end
  
  def keep?
    no = lambda do |reason|
      Merb.logger.info "Ignoring URL #{url}: #{reason}"
      IgnoredUrl.ignore(url, reason)
      false
    end
    
    return no['description in French'] if exif['LanguageIdentifier'] == 'fr'
    return no['AFP advisory'] if exif['OriginalTransmissionReference'] == 'ADVISORY'
    return no['AFP advisory'] if exif['OriginalTransmissionReference'] == 'AFP01'
    
    true
  end
  
  private
    def data_valid?(data)
      return false if data.nil?
      
      if expected_size && data.length != expected_size
        Merb.logger.warn "Downloaded data for Photo[#{id}] was #{data.length} bytes, expected #{expected_size} bytes"
        return false
      elsif data.length < 1024
        Merb.logger.warn "Downloaded data for Photo[#{id}] was too small (<1kB)"
        return false
      end

      true
    end
end
