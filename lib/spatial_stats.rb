# frozen_string_literal: true

require 'spatial_stats/railtie'
require 'spatial_stats/enumerable_ext'
require 'spatial_stats/global'
require 'spatial_stats/local'
require 'spatial_stats/matrix_ext'
require 'spatial_stats/queries'
require 'spatial_stats/utils'
require 'spatial_stats/weights'

module SpatialStats
  def self.included(klass)
    puts 'here', klass
    # klass.extend(SpatialStats::Queries::Weights)
  end
  # Your code goes here...
end
