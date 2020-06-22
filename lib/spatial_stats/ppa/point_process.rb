# frozen_string_literal: true

require 'rubystats'

module SpatialStats
  module PPA
    ##
    # Poisson Point Process methods
    #
    # PointProcess contains methods that define a CSR process
    # and can generate random points within a bounding box.
    module PointProcess
      ##
      # Compute n random points in a bounding box.
      # Uses uniform distributions in x and y to compute n points.
      #
      # @param [Array] bbox of a PointPattern [[xmin,ymin], [xmax,ymax]]
      # @param [Integer] n points to be generated
      #
      # @returns [Array] of points
      def self.generate_from_n(bbox, n)
        # define uniform distributions in x and y
        x_dist = Rubystats::UniformDistribution.new(bbox[0][0], bbox[1][0])
        y_dist = Rubystats::UniformDistribution.new(bbox[0][1], bbox[1][1])
        n.times.map do
          [x_dist.rng, y_dist.rng]
        end
      end

      ##
      # Compute random points in a bounding box given the intensity.
      # Uses a poisson distribution to compute n from the given intensity
      # and generates points with that.
      #
      # @param [Array] bbox of a PointPattern [[xmin,ymin], [xmax,ymax]]
      # @param [Integer] lambda intensity of distribution
      #
      # @returns [Array] of points
      def self.generate_from_lambda(bbox, lam)
        poisson = Rubystats::PoissonDistribution.new(lam)
        n = poisson.rng
        generate_from_n(bbox, n)
      end
    end
  end
end
