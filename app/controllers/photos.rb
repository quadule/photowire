class Photos < Application
  def index
    model = Photo.downloaded
    
    model = model.all(:wire_id => 1) if params[:wire] == 'ap'
    model = model.all(:wire_id => 2) if params[:wire] == 'afp'
    
    if params[:filename]
      model = model.all(:path.like => "%#{params[:filename]}%")
    end
    
    if params[:date]
      date = Date.parse(params[:date])
      model = model.all(
        :published_at.gte => date,
        :published_at.lte => date+1
      )
    end
    
    if params[:search]
      model = model.all :description.like => "%#{params[:search]}%"
    end
    
    if params[:attribute].is_a?(Hash)
      #FIXME: this doesn't actually work for multiple attribute key/value pairs
      params[:attribute].each do |id, value|
        model = model.all(
          :links => [:exif_attributes],
          Photo.exif_attributes.exif_attribute_id => id,
          Photo.exif_attributes.value => value
        )
      end
    end
    
    paginate_model model
    render :index
  end
  
  def show
    @photo = Photo.get(params[:id])
    render
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

      @pages, @photos = model.paginated({
        :page =>     @page,
        :per_page => @per_page
      }.merge(order))
    end
end