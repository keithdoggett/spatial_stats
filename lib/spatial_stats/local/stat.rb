# frozen_string_literal: true

module SpatialStats
  module Local
    class Stat
      # Base class for local stats
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_accessor :scope, :field, :weights

      def i
        raise NotImplementedError, 'method i not defined'
      end

      def i_i
        raise NotImplementedError, 'method i_i not defined'
      end

      def expectation
        raise NotImplementedError, 'method expectation not implemented'
      end

      def variance
        raise NotImplementedError, 'method variance not implemented'
      end

      def z_score
        numerators = i.map { |v| v - expectation }
        denominators = variance.map { |v| Math.sqrt(v) }
        numerators.each_with_index.map do |numerator, idx|
          numerator / denominators[idx]
        end
      end

      def crand(arr, permutations, rng)
        # conditional randomization method
        # will generate an n x permutations array of arrays.
        # For each n, i will be held the same and the values around it will
        # be permutated.
        arr.each_with_index.map do |xi, idx|
          tmp_arr = arr.clone
          tmp_arr.delete_at(idx)
          permutations.times.map do
            perm = tmp_arr.shuffle(random: rng)
            perm.insert(idx, xi)
          end
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
    end
  end
end
