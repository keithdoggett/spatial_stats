# frozen_string_literal: true

require 'spatial_stats/ppa/centrography'

module SpatialStats
  ##
  # The PPA module provides functionality for point pattern analysis.
  # It includes support for descriptive statistics and distance analysis.
  #
  # Also has support for database connections for tables that have
  # x,y columns or are a Point from PostGIS.
  module PPA
    ##
    # PointPattern class holds an array of points and performs various
    # analysis on them.
    #
    class PointPattern
      ##
      # A new instance of PointPattern.
      #
      # Points are an array of arrays of floats, ex.
      #  @example
      #   pts = [[0,1], [1.25, 3.25]]
      #   SpatialStats::PPA::PointPattern.new(pts)
      #
      #
      # @param [Array] array of x,y tuples
      #
      # @returns [PointPattern]
      def initialize(points)
        @points = points
        @n = points.size
      end
      attr_accessor :points, :n
    end
  end
end