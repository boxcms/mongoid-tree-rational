require File.join(File.dirname(__FILE__), 'lib','mongoid', 'tree', 'version')

Gem::Specification.new do |s|
  s.name          = "mongoid-tree-rational"
  s.homepage      = "https://github.com/boxcms/mongoid-tree-rational"
  s.summary       = "A tree structure for Mongoid documents with rational numbers"
  s.description   = "A tree structure for Mongoid documents using the materialized path pattern and rational number sorting."

  s.authors       = ["Leif Ringstad", "Benedikt Deicke"]
  s.email         = "leifcr@gmail.com"
  s.version       = Mongoid::RationalTree::VERSION
  s.platform      = Gem::Platform::RUBY
  s.files         = Dir.glob('lib/**/*') + %w[Gemfile Rakefile README.md VERSION LICENSE]
  s.test_files    = Dir.glob('spec/**/*')

  s.require_paths = ["lib"]
  s.date          = "2014-08-20"

  s.licenses      = ["MIT"]

  s.add_runtime_dependency(     'mongoid',  ['<= 5.0', '>= 4.0'])
  s.add_runtime_dependency(     'i18n',     ['>= 0.6'])

  s.add_development_dependency( 'rake',     ['>= 0.9.2'])
  s.add_development_dependency( 'rspec',    ['~> 3.0'])
  s.add_development_dependency( 'yard',     ['~> 0.8'])
  s.add_development_dependency( 'timecop',  ['>= 0.7'])
  # s.add_development_dependency('simplecov', ['>= 0.9'])
  # s.add_development_dependency('coveralls', ['>= 0.9'])
end

