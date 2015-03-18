source 'http://github.com/sapcc:8080/rubygemsorg/'
source 'http://github.com/sapcc:8080/geminabox/'

# Declare your gem's dependencies in monsoon_identity.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem 'activerecord-session_store', '~> 0.1.0'
gem 'monsoon-fog', git: 'git://github.com/sapcc/monsoon/monsoon-fog.git'

group :development, :test do
  gem 'rspec-rails', "~> 2.99.0"
  gem 'factory_girl_rails', "~> 4.0"
  gem 'guard-rspec', :require => false
  gem 'vcr'
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'
