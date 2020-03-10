# frozen_string_literal: true

# https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-how-cluster-and-outlier-analysis-anselin-local-m.htm
# For now, instead of doing neighbor's variance (Si**2), I'm going to use
# the total sample variance. This is how GeoDa does it, but is different
# than arcgis. This shouldn't affect the expectation and variance of I.
module SpatialStats
  module Local
    class Morans
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_accessor :scope, :field, :weights

      def i
        si2 = z.sample_variance
        w = @weights.full
        z_lag = SpatialStats::Utils::Lag.neighbor_average(w, z)
        vector = []

        z.each_with_index do |z_val, idx|
          sum_term = z_lag[idx]
          vector << (z_val / si2) * sum_term
        end
        vector
      end

      def expectation
        # since we are using row standardized weights, the expectation
        # will just be -1/(n-1) for all items. Otherwise, it would be
        # a vector where the sum of the weights for each row is the numerator
        # in the equation.
        -1.0 / (@weights.keys.size - 1)
      end

      def variance
        # formula is A - B - (E[I])**2
        w = @weights.full.row_standardized
        exp = expectation

        vars = []
        a_terms = a_calc(w)
        b_terms = b_calc(w)

        a_terms.each_with_index do |a_term, idx|
          vars << (a_term - b_terms[idx] - (exp**2))
        end
        vars
      end

      def z_score
        numerators = i.map { |v| v - expectation }
        denominators = variance.map { |v| Math.sqrt(v) }
        numerators.each_with_index.map do |numerator, idx|
          numerator / denominators[idx]
        end
      end

      def quads
        # https://github.com/pysal/esda/blob/master/esda/moran.py#L925
        w = @weights.full
        z_lag = SpatialStats::Utils::Lag.neighbor_average(w, z)
        zp = z.map { |v| v > 0 }
        lp = z_lag.map { |v| v > 0 }

        # hh = zp & lp
        # lh = zp ^ true & lp
        # ll = zp ^ true & lp ^ true
        # hl = zp next to lp ^ true
        hh = zp.each_with_index.map { |v, idx| v & lp[idx] }
        lh = zp.each_with_index.map { |v, idx| (v ^ true) & lp[idx] }
        ll = zp.each_with_index.map { |v, idx| (v ^ true) & (lp[idx] ^ true) }
        hl = zp.each_with_index.map { |v, idx| v & (lp[idx] ^ true) }

        # now zip lists and map them to proper terms
        quad_terms = %w[HH LH LL HL]
        hh.zip(lh, ll, hl).map do |feature|
          quad_terms[feature.index(true)]
        end
      end

      def variables
        @variables ||= SpatialStats::Queries::Variables
                       .query_field(@scope, @field).standardize
      end

      def zbar
        variables.sum / variables.size
      end

      def z
        variables.map { |val| val - zbar }
      end

      private

      # https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-local-morans-i-additional-math.htm
      def a_calc(w)
        n = w.row_size
        b2i = b2i_calc
        a_terms = []

        (0..n - 1).each do |idx|
          sigma_term = w.row(idx).sum { |v| v**2 }
          a_terms << (n - b2i) * sigma_term / (n - 1)
        end
        a_terms
      end

      def b_calc(w)
        n = w.row_size
        b2i = b2i_calc
        b_terms = []

        (0..n - 1).each do |idx|
          sigma_term = 0
          (0..n - 1).each do |k|
            (0..n - 1).each do |h|
              sigma_term += w[idx, k] * w[idx, h]
            end
          end
          b_terms << sigma_term * (2 * b2i - n) / ((n - 1) * (n - 2))
        end
        b_terms
      end

      def b2i_calc
        numerator = z.sum { |v| v**4 }
        denominator = z.sum { |v| v**2 }
        numerator / (denominator**2)
      end
    end
  end
end
