# frozen_string_literal: true

module SpatialStats
  module Global
    ##
    # BivariateMoran computes the correlation between a variable x and
    # a spatially lagged variable y.
    class BivariateMoran < Stat
      ##
      # A new instance of BivariateMoran
      #
      # @param [ActiveRecord::Relation] scope
      # @param [Symbol, String] x_field to query from scope
      # @param [Symbol, String] y_field to query from scope
      # @param [WeightsMatrix] weights to define relationship between observations in scope
      #
      # @return [BivariateMoran]
      def initialize(scope, x_field, y_field, weights)
        @scope = scope
        @x_field = x_field
        @y_field = y_field
        @weights = weights.standardize
      end

      ##
      # A new instance of BivariateMoran, from vector and weights.
      #
      # @param [Array] x observations of dataset
      # @param [WeightsMatrix] weights to define relationships between observations
      #
      # @return [BivariateMoran]
      def self.from_observations(x, y, weights)
        n = weights.n
        raise ArgumentError, 'Data size != weights.n' if x.size != n || y.size != n

        instance = new(nil, nil, nil, weights.standardize)
        instance.x = x
        instance.y = y
        instance
      end

      ##
      # Computes the global spatial correlation of x against spatially lagged
      # y.
      #
      # @return [Float]
      def stat
        y_lag = SpatialStats::Utils::Lag.neighbor_sum(weights, y)
        numerator = 0
        x.each_with_index do |xi, idx|
          numerator += xi * y_lag[idx]
        end

        denominator = x.sum { |xi| xi**2 }
        numerator / denominator
      end
      alias i stat

      ##
      # The expected value of +#stat+.
      # @see https://en.wikipedia.org/wiki/Moran%27s_I#Expected_value
      # @return [Float]
      def expectation
        -1.0 / (@weights.n - 1)
      end

      ##
      # The variance of the bivariate spatial correlation.
      # @see https://en.wikipedia.org/wiki/Moran%27s_I#Expected_value
      #
      # @return [Float]
      def variance
        n = weights.n
        w_sum = n.to_f
        e = expectation

        wij = weights.sparse.coordinates

        s1 = s1_calc(wij)
        s2 = s2_calc(n, wij, weights.sparse.row_index)
        s3 = s3_calc(n, x)

        s4 = (n**2 - 3 * n + 3) * s1 - n * s2 + 3 * (w_sum**2)
        s5 = (n**2 - n) * s1 - 2 * n * s2 + 6 * (w_sum**2)

        var_left = (n * s4 - s3 * s5) / ((n - 1) * (n - 2) * (n - 3) * w_sum**2)
        var_right = e**2
        var_left - var_right
      end

      ##
      # Permutation test to determine a pseudo p-value of the computed I stat.
      # Shuffles y values while holding x constant and recomputing I for each
      # variation, then compares that I value to the computed one.
      # The ratio of more extreme values to permutations is returned.
      #
      # @see https://geodacenter.github.io/glossary.html#perm
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Float]
      def mc(permutations = 99, seed = nil)
        mc_bv(permutations, seed)
      end

      ##
      # Summary of the statistic. Computes +stat+ and +mc+ and returns the values
      # in a hash.
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Hash]
      def summary(permutations = 99, seed = nil)
        p_val = mc(permutations, seed)
        { stat: stat, p: p_val }
      end

      ##
      # Standardized variables queried from +x_field+.
      #
      # @return [Array]
      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @x_field)
                                               .standardize
      end

      ##
      # Standardized variables queried from +y_field+.
      #
      # @return [Array]
      def y
        @y ||= SpatialStats::Queries::Variables.query_field(@scope, @y_field)
                                               .standardize
      end

      private

      def stat_mc(perms)
        x_arr = Numo::DFloat.cast(x)
        lag = w.dot(perms.transpose)
        x_arr.dot(lag) / (x_arr**2).sum
      end

      def s3_calc(n, zs)
        numerator = (1.0 / n) * zs.sum { |v| v**4 }
        denominator = ((1.0 / n) * zs.sum { |v| v**2 })**2
        numerator / denominator
      end

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
