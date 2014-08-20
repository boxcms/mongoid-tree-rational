source 'https://rubygems.org'

group :development do
  gem 'guard-rspec', '>= 2.6.0'
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'wdm', :platforms => [:mswin, :mingw], :require => false
  gem 'awesome_print'
  platforms :rbx do
    gem 'rubysl-rake', '~> 2.0'
  end
end

group :development, :test do
  gem 'coveralls', :require => false
  gem 'simplecov', :require => false
end

gemspec
