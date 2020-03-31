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

      def crand(arr, permutations, rng)
        # basing this off the ESDA method
        # need to get k for max_neighbors
        # and wc for cardinalities of each item
        # this returns an array of length n with
        # (permutations x neighborz) Numo Arrays.
        # This helps reduce computation time because
        # we are only dealing with neighbors for each
        # entry not the entire list of permutations for each entry.
        wc = weights.weights.values.map(&:size)
        k = wc.max + 1
        n_1 = weights.n - 1
        prange = (0..permutations - 1).to_a

        arr = Numo::DFloat.cast(arr)

        ids = (0..n_1).to_a
        ids_perm = (0..n_1 - 1).to_a
        rids = Numo::Int32.cast(prange.map { ids_perm.sample(k, random: rng) })

        (0..n_1).map do |idx|
          idsi = ids.dup
          idsi.delete_at(idx)
          idsi.shuffle!(random: rng)
          idsi = Numo::Int32.cast(idsi)
          arr[idsi[rids[true, 0..wc[idx] - 1]]]
        end
      end

      def mc(permutations = 99, seed = nil)
        # For local tests, we need to shuffle the values
        # but for each item, hold its value in place and shuffle
        # its neighbors. Then we will only test for that item instead
        # of the entire set. This will be done for each item.
        rng = gen_rng(seed)
        shuffles = crand(x, permutations, rng)
        n = shuffles.size
        # r is the number of equal to or more extreme samples
        i_orig = i
        rs = [0] * i_orig.size

        ws = weights.weights.values.map do |neighbors|
          neighbors.map { |v| v[:weight] }
        end

        # For each shuffle, we only need the spatially lagged variable
        # at one index, but it needs to be an array of length n.
        # Store a zeros array that can be mutated or duplicated and the
        # lagged variable at idx will only be set there.
        idx = 0
        while idx < n
          ii_orig = i_orig[idx]
          z_lag = (Numo::DFloat.cast(ws[idx]) * shuffles[idx]).sum(1)
          ii_new = z[idx] * z_lag
          rs[idx] = if ii_orig.positive?
                      (ii_new >= ii_orig).count
                    else
                      (ii_new <= ii_orig).count
                    end

          idx += 1
        end

        rs.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

      def z_lag
        # can't memoize yet because of mc testing
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
