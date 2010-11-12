class Photos < Application
  before :require_admin, :only => [:destroy, :update]
  
  def index
    @description = []
    model = Photo.downloaded
    
    model = model.all(:wire_id => 1) if params[:wire] == 'ap'
    model = model.all(:wire_id => 2) if params[:wire] == 'afp'
    
    if params[:filename]
      @description << "with a filename containing \"#{params[:filename]}\""
      model = model.all(:path.like => "%#{params[:filename]}%")
    end
    
    if params[:date]
      date = Date.parse(params[:date])
      @description << "taken on #{params[:date]}"
      model = model.all(
        :published_at.gte => date,
        :published_at.lte => date+1
      )
    end
    
    if params[:search]
      @description << "with a caption containing \"#{params[:search]}\""
      model = model.all :description.like => "%#{params[:search]}%"
    end
    
    if params[:attribute].is_a?(Hash)
      #FIXME: this doesn't actually work for multiple attribute key/value pairs
      params[:attribute].each do |id, value|
        @description << "where #{ExifAttribute.get!(id).name} = \"#{value}\""
        model = model.all(
          :links => [:exif_attributes],
          Photo.exif_attributes.exif_attribute_id => id,
          Photo.exif_attributes.value => value
        )
      end
    end
    
    @description = @description.join(' and ') unless @description.empty?
    paginate_model model
    render :index
  end
  
  def show
    @photo = Photo.get!(params[:id])
    render
  end
  
  def destroy
    Photo.get!(params[:id]).destroy
    redirect url(:photos)
  end
  
  def update
    @photo = Photo.get!(params[:id])
    @photo.update_attributes(params[:photo])
    redirect url(:photo, @photo)
  end
  
  private
    def order
      #TODO: override with something from params
      {:order => [:published_at.desc]}
    end
    
    def paginate_model(model)
      @page = (params[:page] || 1).to_i
      @page = 1 if @page <= 0
      
      @per_page = (params[:per_page] || 18).to_i
      @per_page = 1 if @per_page <= 0
      
      @pages, @photos, @total = model.paginated({
        :page =>     @page,
        :per_page => @per_page
      }.merge(order))
    end
end