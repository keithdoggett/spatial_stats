# frozen_string_literal: true

module SpatialStats
  module Local
    ##
    # BivariateMoran computes the local correlation between a variable x and
    # spatially lagged variable y.
    class BivariateMoran < Stat
      ##
      # A new instance of BivariateMoran
      #
      # @param [ActiveRecord::Relation] scope
      # @param [Symbol, String] x_field to query from scope
      # @param [Symbol, String] y_field to query from scope
      # @param [WeightsMatrix] weights to define relationship between observations in scope
      #
      # @return [Moran]
      def initialize(scope, x_field, y_field, weights)
        @scope = scope
        @x_field = x_field
        @y_field = y_field
        @weights = weights.standardize
      end
      attr_accessor :scope, :x_field, :y_field, :weights

      ##
      # Computes the local indicator of spatial correlation for
      # x against lagged y.
      #
      # @return [Array] of correlations for each observation.
      def stat
        x.each_with_index.map do |_xi, idx|
          stat_i(idx)
        end
      end
      alias i stat

      ##
      # Computes Bivariate Moran's I at a single index. Multiplies x at
      # this index by the lagged y value at this index.
      #
      # @param [Integer] idx to perfrom the calculation on
      #
      # @return [Float] correlation at idx
      def stat_i(idx)
        x[idx] * y_lag[idx]
      end

      ##
      # Permutation test to determine a pseudo p-values of the +#stat+ method.
      # Shuffles y values, hold x values, recomputes +#stat+ for each variation,
      # then compares to the computed one. The ratio of more extreme values to
      # permutations is returned for each observation.
      #
      # @see https://geodacenter.github.io/glossary.html#perm
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Array] of p-values
      def mc(permutations = 99, seed = nil)
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

      def mc_i(wi, perms, idx)
        y_lag_i = (wi * perms).sum(1)
        x[idx] * y_lag_i
      end

      def mc_observation_calc(stat_i_orig, stat_i_new, _permutations)
        # Since moran can be positive or negative, go by this definition
        if stat_i_orig.positive?
          (stat_i_new >= stat_i_orig).count
        else
          (stat_i_new <= stat_i_orig).count
        end
      end

      def y_lag
        @y_lag ||= SpatialStats::Utils::Lag.neighbor_sum(weights, y)
      end
    end
  end
end
