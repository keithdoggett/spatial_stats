# frozen_string_literal: true

module SpatialStats
  module Global
    ##
    # Moran's I statistic computes the spatial autocorrelation of variable x.
    # It does this by computing a spatially lagged version of itself and
    # comparing that with each observation based on the weights matrix.
    class Moran < Stat
      ##
      # A new instance of Moran
      #
      # @param [ActiveRecord::Relation] scope
      # @param [Symbol, String] field to query from scope
      # @param [WeightsMatrix] weights to define relationship between observations in scope
      #
      # @return [Moran]
      def initialize(scope, field, weights)
        super(scope, field, weights)
      end
      attr_writer :x

      ##
      # Computes the global spatial autocorrelation of x against a spatially
      # lagged x.
      #
      # @return [Float]
      def stat
        # compute's Moran's I. numerator is sum of zi * spatial lag of zi
        # denominator is sum of zi**2.
        # have to use row-standardized weights
        z_lag = SpatialStats::Utils::Lag.neighbor_sum(weights, z)
        numerator = 0
        z.each_with_index do |zi, j|
          row_sum = zi * z_lag[j]
          numerator += row_sum
        end

        denominator = z.sum { |zi| zi**2 }
        numerator / denominator
      end
      alias i stat

      ##
      # The expected value of +#stat+.
      # @see https://en.wikipedia.org/wiki/Moran%27s_I#Expected_value
      #
      # @return [Float]
      def expectation
        # -1/(n-1)
        -1.0 / (weights.n - 1)
      end

      ##
      # The variance of the spatial correlation.
      # @see https://en.wikipedia.org/wiki/Moran%27s_I#Expected_value
      #
      # @return [Float]
      def variance
        n = weights.n
        w_sum = n # standardized weights
        e = expectation

        wij = weights.sparse.coordinates

        s1 = s1_calc(wij)
        s2 = s2_calc(n, wij, weights.sparse.row_index)
        s3 = s3_calc(n, z)

        s4 = (n**2 - 3 * n + 3) * s1 - n * s2 + 3 * (w_sum**2)
        s5 = (n**2 - n) * s1 - 2 * n * s2 + 6 * (w_sum**2)

        var_left = (n * s4 - s3 * s5) / ((n - 1) * (n - 2) * (n - 3) * w_sum**2)
        var_right = e**2
        var_left - var_right
      end

      ##
      # Permutation test to determine a pseudo p-value of the computed I stat.
      # Shuffles x values recomputes I for each variation, then compares that I
      # value to the computed one. The ratio of more extreme values to
      # permutations is returned.
      #
      # @see https://geodacenter.github.io/glossary.html#perm
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Float]
      def mc(permutations = 99, seed = nil)
        super(permutations, seed)
      end

      ##
      # Values of the +field+ queried from the +scope+
      #
      # @return [Array]
      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

      private

      def stat_mc(perms)
        z_arr = Numo::DFloat.cast(z)
        lag = w.dot(perms.transpose)
        z_arr.dot(lag) / (z_arr**2).sum
      end

      def s3_calc(n, zs)
        numerator = (1.0 / n) * zs.sum { |v| v**4 }
        denominator = ((1.0 / n) * zs.sum { |v| v**2 })**2
        numerator / denominator
      end

      # use row_index to take slices of wij
      def s2_calc(n, wij, row_index)
        s2 = 0
        wij_arr = wij.to_a # for row slicing
        (0..n - 1).each do |idx|
          row = wij_arr[row_index[idx]..(row_index[idx + 1] - 1)]
          left_term = 0
          right_term = 0

          row.each do |coords, val|
            left_term += val
            right_term += wij[coords.reverse] || 0
          end
          s2 += (left_term + right_term)**2
        end
        s2
      end

      def s1_calc(wij)
        s1 = 0
        wij.each do |coords, val|
          # (wij + wji)**2
          wji = wij[coords.reverse] || 0
          s1 += (val + wji)**2
        end
        s1 / 2
      end
    end
  end
end
