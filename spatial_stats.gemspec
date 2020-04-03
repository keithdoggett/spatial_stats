# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'spatial_stats/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'spatial_stats'
  spec.version     = SpatialStats::VERSION
  spec.authors     = ['Keith Doggett']
  spec.email       = ['keith.doggett887@gmail.com']
  spec.homepage    = 'https://www.github.com/keithdoggett/spatial_stats'
  spec.summary     = 'An ActiveRecord/PostGIS extension that provides statistical methods to spatial postgresql databases.'
  spec.description = 'An ActiveRecord/PostGIS extension that provides '\
                     'statistical methods to spatial postgresql databases. '\
                     'It integrates with ActiveRecord to perform spatial weighting'\
                     ' in PostGIS and performs statistical computations '\
                     'inside your rails app. Supports contiguious and distance-based'\
                     ' calculations.'
  spec.license     = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['documentation_uri'] = 'https://keithdoggett.github.io/spatial_stats/'
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'numo-narray', '~>0.9.1'
  spec.add_dependency 'rails', '~> 6.0.0'
  spec.add_development_dependency 'activerecord-postgis-adapter', '~> 6.0.0'
  spec.add_development_dependency 'database_cleaner', '~> 1.8.3'
  spec.add_development_dependency 'pg', '~> 1.0'
  spec.add_development_dependency 'ruby-prof', '~> 1.3.1'
  spec.add_development_dependency 'tzinfo', '~> 1.2.6'
end
