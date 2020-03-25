# frozen_string_literal: true

# https://geodacenter.github.io/workbook/5b_global_adv/lab5b.html
module SpatialStats
  module Global
    class BivariateMoran < Stat
      def initialize(scope, x_field, y_field, weights)
        @scope = scope
        @x_field = x_field
        @y_field = y_field
        @weights = weights
      end
      attr_writer :x, :y

      def i
        w = @weights.full
        y_lag = SpatialStats::Utils::Lag.neighbor_average(w, y)
        numerator = 0
        x.each_with_index do |xi, idx|
          numerator += xi * y_lag[idx]
        end

        denominator = x.sum { |xi| xi**2 }
        numerator / denominator
      end

      def expectation
        -1.0 / (@weights.keys.size - 1)
      end

      def variance
        # https://en.wikipedia.org/wiki/Moran%27s_I#Expected_value
        n = @weights.keys.size
        wij = @weights.full
        w = wij.sum
        e = expectation

        s1 = s1_calc(n, wij)
        s2 = s2_calc(n, wij)
        s3 = s3_calc(n, x)

        s4 = (n**2 - 3 * n + 3) * s1 - n * s2 + 3 * (w**2)
        s5 = (n**2 - n) * s1 - 2 * n * s2 + 6 * (w**2)

        var_left = (n * s4 - s3 * s5) / ((n - 1) * (n - 2) * (n - 3) * w**2)
        var_right = e**2
        var_left - var_right
      end

      def mc(permutations = 99, seed = nil)
        # call super monte carlo for multivariate
        mc_bv(permutations, seed)
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @x_field)
                                               .standardize
      end

      def y
        @y ||= SpatialStats::Queries::Variables.query_field(@scope, @y_field)
                                               .standardize
      end

      private

      def s3_calc(n, zs)
        numerator = (1.0 / n) * zs.sum { |v| v**4 }
        denominator = ((1.0 / n) * zs.sum { |v| v**2 })**2
        numerator / denominator
      end

      def s2_calc(n, wij)
        s2 = 0
        (0..n - 1).each do |i|
          left_term = 0
          right_term = 0
          (0..n - 1).each do |j|
            left_term += wij[i, j]
            right_term += wij[j, i]
          end
          s2 += (left_term + right_term)**2
        end
        s2
      end

      def s1_calc(n, wij)
        s1 = 0
        (0..n - 1).each do |i|
          (0..n - 1).each do |j|
            s1 += (wij[i, j] + wij[j, i])**2
          end
        end
        s1 / 2
      end
    end
  end
end
