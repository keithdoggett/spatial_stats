# frozen_string_literal: true

module SpatialStats
  module Global
    class Moran < Stat
      def initialize(scope, field, weights)
        super(scope, field, weights)
      end
      attr_writer :x

      def i
        # compute's Moran's I. numerator is sum of zi * spatial lag of zi
        # denominator is sum of zi**2.
        # have to use row-standardized
        @i ||= begin
          w = @weights.standardized
          z_lag = SpatialStats::Utils::Lag.neighbor_sum(w, z)
          numerator = 0
          z.each_with_index do |zi, j|
            row_sum = zi * z_lag[j]
            numerator += row_sum
          end

          denominator = z.sum { |zi| zi**2 }
          numerator / denominator
        end
      end

      def expectation
        # -1/(n-1)
        -1.0 / (@weights.n - 1)
      end

      def variance
        # https://en.wikipedia.org/wiki/Moran%27s_I#Expected_value
        n = @weights.n
        wij = @weights.full
        w = wij.sum
        e = expectation

        s1 = s1_calc(n, wij)
        s2 = s2_calc(n, wij)
        s3 = s3_calc(n, z)

        s4 = (n**2 - 3 * n + 3) * s1 - n * s2 + 3 * (w**2)
        s5 = (n**2 - n) * s1 - 2 * n * s2 + 6 * (w**2)

        var_left = (n * s4 - s3 * s5) / ((n - 1) * (n - 2) * (n - 3) * w**2)
        var_right = e**2
        var_left - var_right
      end

      def mc(permutations = 99, seed = nil)
        super(permutations, seed)
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
      end

      def zbar
        x.sum / x.size
      end

      def z
        x.map { |val| val - zbar }
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
