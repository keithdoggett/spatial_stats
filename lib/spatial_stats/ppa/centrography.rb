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

      ##
      # Compute the standard distance of a PointPattern
      #
      # Computes the standard deviation of each point from the mean_center
      #
      # @return [Float]
      def standard_distance
        var = 0
        center = mean_center
        points.each do |point|
          var += (point[0] - center[0])**2 + (point[1] - center[1])**2
        end

        Math.sqrt(var / n)
      end

      ##
      # Compute the median of a PointPattern
      #
      # Not the center of minimum distance, but the middle x and middle y
      # values. If the number of points is even, returns the average
      # of medians in each dimension
      #
      # @return [Array] x_median, y_median
      def median
        x_sorted = points.map { |v| v[0] }.sort
        y_sorted = points.map { |v| v[1] }.sort
        if n.even?
          x_val = (x_sorted[(n - 1) / 2] + x_sorted[n / 2]) / 2.0
          y_val = (y_sorted[(n - 1) / 2] + y_sorted[n / 2]) / 2.0
          [x_val, y_val]
        else
          [x_sorted[n / 2], y_sorted[n / 2]]
        end
      end

      ##
      # Compute the median center or center of minimum distance
      # of a PointPattern.
      #
      # This is the point that minimizes the sum of euclidean
      # distances to all points in the data set.
      #
      # This is an iterative algorithm and a tolerance has to be passed
      # to tell the method when to stop iterating.
      #
      # @param [Float] tol to cutoff algorithm
      #
      # @return [Array] x_center, y_center
      def center_median(tol = 1e-4)
        pts = Numo::DFloat.cast(points)
        center = mean_center
        x0 = center[0]
        y0 = center[1]
        dx = Float::INFINITY
        dy = Float::INFINITY
        while dx.abs > tol || dy.abs > tol
          dist = ((pts[nil, 0] - x0)**2 + (pts[nil, 1] - y0)**2)**0.5
          inv_d = 1 / dist
          inv_d /= inv_d.sum

          dot_prod = inv_d.dot(pts)
          x1 = dot_prod[0]
          y1 = dot_prod[1]

          dx = x1 - x0
          dy = y1 - y0

          x0 = x1
          y0 = y1
        end
        [x1, y1]
      end
      alias center_of_minimum_dist center_median

      ##
      # Compute the Standard Deviational Ellipse of the PointPattern
      #
      # Returns the semi-major axis, semi-minor axis, and rotation in rads
      #
      #
      # @return [Array] sx, sy, theta
      def sd_ellipse
        # first theta needs to be computed
        theta = sd_ellipse_theta
        center = mean_center
        cos = Math.cos(theta)
        sin = Math.sin(theta)

        sx = 0.0
        sy = 0.0

        points.each do |point|
          xdiff = point[0] - center[0]
          ydiff = point[1] - center[1]
          sx += (xdiff * cos - ydiff * sin)**2
          sy += (xdiff * sin - ydiff * cos)**2
        end

        sx = 2 * sx / (n - 2)
        sy = 2 * sy / (n - 2)

        sx = Math.sqrt(sx)
        sy = Math.sqrt(sy)

        [sx, sy, theta]
      end

      private

      def sd_ellipse_theta
        xbar2 = 0.0
        ybar2 = 0.0
        diff_product = 0.0
        center = mean_center
        points.each do |point|
          xdiff = point[0] - center[0]
          ydiff = point[1] - center[1]

          diff_product += xdiff * ydiff
          xbar2 += xdiff**2
          ybar2 += ydiff**2
        end

        lhs_numerator = xbar2 - ybar2
        rhs_numerator = Math.sqrt(
          (xbar2 - ybar2)**2 + 4 * diff_product**2
        )
        denominator = 2 * diff_product
        Math.atan((lhs_numerator + rhs_numerator) / denominator)
      end
    end
  end
end
