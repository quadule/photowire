class Photos < Application
  def index
    paginate_model Photo.downloaded.all(order)
    render
  end
  
  def search
    model = Photo.downloaded
    if params[:date]
      date = Date.parse(params[:date])
      model = model.all order.merge(
        :published_at.gte => date,
        :published_at.lte => date+1
      )
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