class Application < Merb::Controller
  before :check_admin
  
  protected
    def check_admin
      @admin ||= basic_authentication.authenticate do |user, password|
        user == 'admin' && Digest::SHA2.hexdigest(Photowire::Secrets::ADMIN_SALT + password) == Photowire::Secrets::ADMIN_PASSWORD
      end
    end
    
    def require_admin
      throw :halt unless check_admin
    end
end