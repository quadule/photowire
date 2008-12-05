class Photos < Application
  def index
    paginate_model Photo.downloaded.all(order)
    render
  end
  
  def search
    model = Photo.downloaded.all(order)
    if params[:date]
      date = Date.parse(params[:date])
      model = model.all(
        :published_at.gte => date,
        :published_at.lte => date+1
      )
    end
    
    if params[:for]
      model = model.all :description.like => "%#{params[:for]}%"
    end
    
    if params[:attribute].is_a?(Hash)
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

      @pages, @photos = model.paginated(
        :page =>     @page,
        :per_page => @per_page
      )
    end
end