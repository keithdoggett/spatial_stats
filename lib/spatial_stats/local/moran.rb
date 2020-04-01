# frozen_string_literal: true

# https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-how-cluster-and-outlier-analysis-anselin-local-m.htm
# For now, instead of doing neighbor's variance (Si**2), I'm going to use
# the total sample variance. This is how GeoDa does it, but is different
# than arcgis. This shouldn't affect the expectation and variance of I.
module SpatialStats
  module Local
    class Moran < Stat
      def initialize(scope, field, weights)
        super(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_writer :x, :z_lag

      def i
        z.each_with_index.map do |_z_val, idx|
          i_i(idx)
        end
      end

      def i_i(idx)
        # method to compute i at a single index.
        # this is important for permutation testing
        # because for each test we only want the result from
        # 1 index not the entire set, so this will save lots of
        # computations.
        sum_term = z_lag[idx]
        (z[idx] / si2) * sum_term
      end

      def expectation
        # since we are using row standardized weights, the expectation
        # will just be -1/(n-1) for all items. Otherwise, it would be
        # a vector where the sum of the weights for each row is the numerator
        # in the equation.
        -1.0 / (@weights.n - 1)
      end

      def variance
        # formula is A - B - (E[I])**2
        wt = w.row_standardized
        exp = expectation

        vars = []
        a_terms = a_calc(wt)
        b_terms = b_calc(wt)

        a_terms.each_with_index do |a_term, idx|
          vars << (a_term - b_terms[idx] - (exp**2))
        end
        vars
      end

      def mc_i(wi, perms, idx)
        # compute i for a single index given DFloat of neighbor weights
        # and DFloat of neighbor z perms
        z_lag_i = (wi * perms).sum(1)
        z[idx] * z_lag_i
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

      def z_lag
        # w is already row_standardized, so we are using
        # neighbor sum instead of neighbor_average to save cost
        @z_lag ||= SpatialStats::Utils::Lag.neighbor_sum(w, z)
      end

      private

      def si2
        # @si2 ||= z.sample_variance
        # we standardize so sample_variance is 1
        1.0
      end

      # https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-local-morans-i-additional-math.htm
      def a_calc(wt)
        n = wt.shape[0]
        b2i = b2i_calc
        a_terms = []

        (0..n - 1).each do |idx|
          sigma_term = wt[idx, true].to_a.sum { |v| v**2 }
          a_terms << (n - b2i) * sigma_term / (n - 1)
        end
        a_terms
      end

      def b_calc(wt)
        n = wt.shape[0]
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
