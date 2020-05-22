# frozen_string_literal: true

module SpatialStats
  module Local
    ##
    # Moran's I statistic computes the spatial autocorrelation of variable x.
    # It does this by computing a spatially lagged version of itself and
    # comparing that with each observation based on the weights matrix.
    # The local version returns the spatial autocorrelation for each
    # observation in the dataset.
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

      ##
      # Computes the local indicator of spatial autocorrelation (lisa) for
      # x against lagged x.
      #
      # @return [Array] of autocorrelations for each observation.
      def stat
        z.each_with_index.map do |_z_val, idx|
          stat_i(idx)
        end
      end
      alias i stat

      ##
      # Expected value of I for each observation. Since the weights matrix
      # is standardized during the calculation, the expectation is the same for
      # each observation.
      #
      # @return [Float]
      def expectation
        # since we are using row standardized weights, the expectation
        # will just be -1/(n-1) for all items. Otherwise, it would be
        # a vector where the sum of the weights for each row is the numerator
        # in the equation.
        -1.0 / (@weights.n - 1)
      end

      ##
      # Variance of I for each observation.
      #
      # @see https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-local-morans-i-additional-math.htm
      #
      # @return [Array] of variances for each observation
      def variance
        # formula is A - B - (E[I])**2
        exp = expectation

        vars = []
        a_terms = a_calc
        b_terms = b_calc

        a_terms.each_with_index do |a_term, idx|
          vars << (a_term - b_terms[idx] - (exp**2))
        end
        vars
      end

      ##
      # Computes the groups each observation belongs to.
      # Potential groups for Moran's I are:
      # [HH] High-High
      # [HL] High-Low
      # [LH] Low-High
      # [LL] Low-Low
      #
      # This is the same as the +#quads+ method in the +Stat+ class.
      #
      # @return [Array] groups for each observation
      def groups
        quads
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

      ##
      # Spatially lagged x variable at each observation.
      #
      # @return [Array]
      def z_lag
        # w is already row_standardized, so we are using
        # neighbor sum instead of neighbor_average to save cost
        @z_lag ||= SpatialStats::Utils::Lag.neighbor_sum(weights, z)
      end

      private

      def stat_i(idx)
        sum_term = z_lag[idx]
        (z[idx] / si2) * sum_term
      end

      def mc_i(wi, perms, idx)
        # compute i for a single index given DFloat of neighbor weights
        # and DFloat of neighbor z perms
        z_lag_i = (wi * perms).sum(1)
        z[idx] * z_lag_i
      end

      def mc_observation_calc(stat_i_orig, stat_i_new, _permutations)
        # Since moran can be positive or negative, go by this definition
        if stat_i_orig.positive?
          (stat_i_new >= stat_i_orig).count
        else
          (stat_i_new <= stat_i_orig).count
        end
      end

      def si2
        # @si2 ||= z.sample_variance
        # we standardize so sample_variance is 1
        1.0
      end

      # https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-local-morans-i-additional-math.htm
      # TODO: sparse
      def a_calc
        n = weights.n
        b2i = b2i_calc

        wts = weights.sparse.values
        row_index = weights.sparse.row_index

        a_terms = []

        (0..n - 1).each do |idx|
          row_range = row_index[idx]..(row_index[idx + 1] - 1)
          wt = wts[row_range]
          sigma_term = wt.sum { |v| v**2 }
          a_terms << (n - b2i) * sigma_term / (n - 1)
        end
        a_terms
      end

      def b_calc
        n = weights.n
        b2i = b2i_calc
        b_terms = []

        # technically, the formula is Sigma k (sigma h (wik * wih))
        # since we use row standardized matricies, this is always 1
        # for each row
        # this also means that all b_terms will be the same.
        sigma_term = 1.0
        b_terms << sigma_term * (2 * b2i - n) / ((n - 1) * (n - 2))
        b_terms * n
      end

      def b2i_calc
        numerator = z.sum { |v| v**4 }
        denominator = z.sum { |v| v**2 }
        numerator / (denominator**2)
      end
    end
  end
end
