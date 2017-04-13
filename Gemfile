# encoding: UTF-8
source 'https://rubygems.org'

gemspec

gem 'excon'

gem 'rails', '>=4.0.0', :groups => [:development, :test]
gem 'dotenv-rails', :groups => [:development, :test]
gem 'sqlite3', :groups => [:development, :test]
gem 'activerecord-session_store', '~> 0.1.0'

group :development, :test do
  gem 'byebug'
end

group :test do
  gem 'webmock'
  gem "rspec-rails"
  gem "factory_girl_rails", "~> 4.0"
  gem 'guard-rspec'
end
