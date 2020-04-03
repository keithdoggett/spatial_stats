# frozen_string_literal: true

require 'spatial_stats/railtie'
require 'spatial_stats/enumerable_ext'
require 'spatial_stats/global'
require 'spatial_stats/local'
require 'spatial_stats/narray_ext'
require 'spatial_stats/queries'
require 'spatial_stats/utils'
require 'spatial_stats/weights'

##
# SpatialStats is an ActiveRecord/PostGIS gem that provides descriptive spatial
# stats to your application.
module SpatialStats
  # def self.included(klass)
  #   puts 'here', klass
  #   # klass.extend(SpatialStats::Queries::Weights)
  # end
  # Your code goes here...
end
