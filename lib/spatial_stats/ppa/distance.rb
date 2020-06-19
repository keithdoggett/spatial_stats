# frozen_string_literal: true

module SpatialStats
  module PPA
    class PointPattern
      ##
      # Returns the index of the K-Nearest Neighbors
      # for every point in the PointPattern
      #
      # @param [Integer] k neighbors
      #
      # @returns [Array] [{idx: Integer, dist: Float}] array of arrays of size k
      def knn(k = 1)
        points.map do |pt|
          # Ignore the first entry because that will be
          # the point passed in
          kd_tree.knn(pt, k + 1).slice(1..k + 1)
        end
      end

      ##
      # Compute the distance of the nearest neighbor to each point
      #
      # @returns [Array] of floats
      def nn_dist
        knn(1).flatten.map { |v| v[:dist] }
      end

      ##
      # Compute the mean nearest neighbor distance to each point
      #
      # @returns [Float]
      def mean_nn_dist
        nn_dist.mean
      end

      ##
      # Compute the standard deviation of the nearest neighbors
      # distance
      #
      # @returns [Float]
      def stddev_nn_dist
        Math.sqrt(nn_dist.sample_variance)
      end

      ##
      # Compute the min nearest neighbor distance to each point
      #
      # @returns [Float]
      def min_nn_dist
        nn_dist.min
      end

      ##
      # Compute the max nearest neighbor distance to each point
      #
      # @returns [Float]
      def max_nn_dist
        nn_dist.max
      end
    end
  end
end
