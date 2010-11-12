source :rubygems

# Dependencies are generated using a strict version,
# Don't forget to edit the dependency versions when upgrading.

merb_gems_version = "1.1.3"
merb_related_gems = "~> 1.1.0"
dm_gems_version   = "~> 1.0"

# If you did disable json for Merb, comment out this line.
# Don't use json gem version lower than 1.1.7! Older version have a security bug

gem "json_pure", ">= 1.4.6", :require => "json"

# For more information about each component,
# please read http://wiki.merbivore.com/faqs/merb_components

gem "merb-core",                merb_gems_version
gem "merb-action-args",         merb_gems_version
gem "merb-assets",              merb_gems_version
gem "merb-helpers",             merb_gems_version
gem "merb-mailer",              merb_gems_version
gem "merb-slices",              merb_gems_version
gem "merb-param-protection",    merb_gems_version
gem "merb-exceptions",          merb_gems_version
gem "merb-gen",                 merb_gems_version

gem("merb-cache", merb_gems_version) do
  Merb::Cache.setup do
    register(Merb::Cache::FileStore) unless Merb.cache
  end
end

gem "merb-auth-core",           merb_related_gems
gem "merb-auth-more",           merb_related_gems
gem "merb-auth-slice-password", merb_related_gems

# Change to server of your choice
gem "thin"

gem "dm-core",                  dm_gems_version
gem "dm-mysql-adapter",        dm_gems_version # change as appropriate
gem "dm-aggregates",            dm_gems_version
gem "dm-migrations",            dm_gems_version
gem "dm-timestamps",            dm_gems_version
gem "dm-types",                 dm_gems_version
gem "dm-validations",           dm_gems_version
gem "dm-serializer",            dm_gems_version
gem "dm-constraints",           dm_gems_version
gem "dm-is-paginated"

gem "merb_datamapper",          merb_related_gems
gem "merb-pagination"
gem "merb-haml"          # Adds rake tasks and the haml generators to your merb app
gem "merb-jquery"        # Provides a #jquery method to insert jQuery code in to a content block

gem "rmagick"
gem "mini_exiftool"
gem "hpricot"
gem "ruby-debug"
gem "mongrel"