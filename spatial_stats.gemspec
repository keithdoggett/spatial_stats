# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'spatial_stats/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'spatial_stats'
  spec.version     = SpatialStats::VERSION
  spec.authors     = ['Keith Doggett']
  spec.email       = ['kfdoggett@gmail.com']
  spec.homepage    = 'https://github.com/keithdoggett/spatial_stats'
  spec.summary     = 'An ActiveRecord/PostGIS extension that provides statistical methods to spatial postgresql databases.'
  spec.description = 'An ActiveRecord/PostGIS extension that provides '\
                     'statistical methods to spatial postgresql databases. '\
                     'It integrates with ActiveRecord to perform spatial weighting'\
                     ' in PostGIS and performs statistical computations '\
                     'inside your rails app. Supports contiguious and distance-based'\
                     ' calculations.'
  spec.license     = 'BSD-3-Clause'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['documentation_uri'] = 'https://keithdoggett.github.io/spatial_stats/'
  spec.metadata['changelog_uri'] = 'https://github.com/keithdoggett/spatial_stats/blob/master/CHANGELOG.md'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = Dir['{app,config,db,lib,ext}/**/*', 'LICENSE', 'Rakefile', 'README.md']
  spec.extensions = ['ext/spatial_stats/extconf.rb']

  spec.add_dependency 'numo-narray', '~>0.9.1'
  spec.add_dependency 'rails', '~> 6.0.0'
  spec.add_dependency 'rubystats', '~>0.3.0'
  spec.add_development_dependency 'activerecord-postgis-adapter', '~> 6.0.0'
  spec.add_development_dependency 'database_cleaner', '~> 1.8.3'
  spec.add_development_dependency 'pg', '~> 1.0'
  spec.add_development_dependency 'rake-compiler', '~>1.1.0'
  spec.add_development_dependency 'ruby-prof', '~> 1.3.1'
  spec.add_development_dependency 'tzinfo', '~> 1.2.6'
end
