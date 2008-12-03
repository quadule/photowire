module Merb
  module PhotosHelper
    def public_path(path)
      path.sub(/^public/, '')
    end
  end
end # Merb