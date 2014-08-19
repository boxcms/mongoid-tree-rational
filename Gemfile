source 'https://rubygems.org'

gem 'mongoid', ['<= 5.0', '>= 4.0']
gem 'rational_number'

group :development do
  gem 'rake'
  gem 'rspec'
  gem 'yard'
  gem 'jeweler'
  gem 'guard-rspec', '>= 2.6.0'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'wdm', :platforms => [:mswin, :mingw], :require => false
  gem 'awesome_print'
  gem 'timecop'
end

group :development, :test do
  gem 'coveralls', :require => false
  gem 'simplecov', :require => false
end

platforms :rbx do
  gem 'rubysl-rake', '~> 2.0'
end
