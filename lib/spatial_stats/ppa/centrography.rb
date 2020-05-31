# frozen_string_literal: true

module SpatialStats
  module PPA
    class PointPattern
      ##
      # Compute the mean center of a PointPattern
      #
      # Computes the arithmetic mean of the x and y values
      # and returns x_mean and y_mean in an array.
      #
      # @returns [Array] x_mean, y_mean tuple
      def mean_center
        x = 0.0
        y = 0.0
        points.each do |point|
          x += point[0]
          y += point[1]
        end

        [x / n, y / n]
      end

      ##
      # Compute the weighted mean center of a PointPattern
      #
      # Computes the weighted mean of the x and y values based on each
      # point's corresponding weight
      #
      # @param [Array] weights
      #
      # @return [Array] x_weighted_mean, y_weighted_mean
      def weighted_mean_center(weights)
        raise ArgumentError, 'weights.size != n' unless weights.size == n

        w_sum = 0.0
        x = 0.0
        y = 0.0
        points.each_with_index do |point, i|
          w_sum += weights[i]
          x += point[0] * weights[i]
          y += point[1] * weights[i]
        end

        [x / w_sum, y / w_sum]
      end
    end
  end
end
