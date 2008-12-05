module Merb
  module PhotosHelper
    def public_path(path)
      path.sub(/^public/, '')
    end
    
    def search_query
      request.query_string.gsub(/&?page=\d+/, '')
    end
  end
end # Merb