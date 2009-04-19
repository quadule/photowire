class Root < Application
  def index
    redirect url(:photos)
  end
  
  def about
    render
  end
  
  def admin
    if @admin && !params[:off]
      redirect url(:photos)
    else
      basic_authentication.request!
    end
  end
end