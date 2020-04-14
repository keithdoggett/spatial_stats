# frozen_string_literal: true

module SpatialStats
  module Local
    ##
    # Stat is the abstract base class for local stats.
    # It defines the methods that are common between all classes
    # and will raise a NotImplementedError on those that are specific
    # for each type of statistic.
    class Stat
      # Base class for local stats
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights.standardized
      end
      attr_accessor :scope, :field, :weights

      def stat
        raise NotImplementedError, 'method stat not defined'
      end

      def expectation
        raise NotImplementedError, 'method expectation not implemented'
      end

      def variance
        raise NotImplementedError, 'method variance not implemented'
      end

      ##
      # Z-score for each observation of the statistic.
      #
      # @return [Array] of the number of deviations from the mean
      def z_score
        numerators = stat.map { |v| v - expectation }
        denominators = variance.map { |v| Math.sqrt(v) }
        numerators.each_with_index.map do |numerator, idx|
          numerator / denominators[idx]
        end
      end

      ##
      # Conditional randomization algorithm used in permutation testing.
      # Outputs an array of length n of Numo::DFloat matrices of
      # size m x num_neighbors. Where m is the number of permutations and
      # num_neighbors is the number of neighbors for that observation.
      #
      # The values are randomly permutated values from arr that will act
      # as its neighbors for that permutation.
      #
      # This is super important because most weight matrices are very
      # sparse so the amount of shuffling/multiplication that is done
      # is reduced drastically.
      #
      # @see https://github.com/pysal/esda/blob/master/esda/moran.py#L893
      #
      # @return [Array] of Numo::Narray matrices
      #
      def crand(arr, permutations, rng)
        # basing this off the ESDA method
        # need to get k for max_neighbors
        # and wc for cardinalities of each item
        # this returns an array of length n with
        # (permutations x neighborz) Numo Arrays.
        # This helps reduce computation time because
        # we are only dealing with neighbors for each
        # entry not the entire list of permutations for each entry.
        n_1 = weights.n - 1

        # weight counts
        wc = [0] * weights.n
        k = 0
        (0..n_1).each do |idx|
          wc[idx] = (w[idx, true] > 0).count
        end

        k = wc.max + 1
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

      ##
      # Permutation test to determine a pseudo p-values of the +#stat+ method.
      # Shuffles x values, recomputes +#stat+ for each variation, then compares
      # to the computed one. The ratio of more extreme values to
      # permutations is returned for each observation.
      #
      # @see https://geodacenter.github.io/glossary.html#perm
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Array] of p-values
      def mc(permutations = 99, seed = nil)
        # For local tests, we need to shuffle the values
        # but for each item, hold its value in place and shuffle
        # its neighbors. Then we will only test for that item instead
        # of the entire set. This will be done for each item.
        rng = gen_rng(seed)
        shuffles = crand(x, permutations, rng)
        n = weights.n
        # r is the number of equal to or more extreme samples
        stat_orig = stat
        rs = [0] * n

        ws = neighbor_weights

        idx = 0
        while idx < n
          # need to truncate because floats from
          # c in sparse matrix are inconsistent with
          # dfloats
          stat_i_orig = stat_orig[idx].truncate(6)

          wi = Numo::DFloat.cast(ws[idx])
          stat_i_new = mc_i(wi, shuffles[idx], idx)

          rs[idx] = if stat_i_orig.positive?
                      (stat_i_new >= stat_i_orig).count
                    else
                      (stat_i_new <= stat_i_orig).count
                    end

          idx += 1
        end

        rs.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
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
      def mc_bv(permutations, seed)
        rng = gen_rng(seed)
        shuffles = crand(y, permutations, rng)
        n = weights.n

        stat_orig = stat
        rs = [0] * n

        ws = neighbor_weights

        idx = 0
        while idx < n
          stat_i_orig = stat_orig[idx]
          wi = Numo::DFloat.cast(ws[idx])
          stat_i_new = mc_i(wi, shuffles[idx], idx)

          rs[idx] = if stat_i_orig.positive?
                      (stat_i_new >= stat_i_orig).count
                    else
                      (stat_i_new <= stat_i_orig).count
                    end

          idx += 1
        end

        rs.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
      end

      ##
      # Determines what quadrant an observation is in. Based on its value
      # compared to its neighbors. This does not work for all stats, since
      # it requires that values be negative.
      #
      # In a standardized array of z, high values are values greater than 0
      # and it's neighbors are determined by the spatial lag and if that is
      # positive then it's neighbors would be high, low otherwise.
      #
      # Quadrants are:
      # [HH] a high value surrounded by other high values
      # [LH] a low value surrounded by high values
      # [LL] a low value surrounded by low values
      # [HL] a high value surrounded by low values
      #
      # @return [Array] of labels
      def quads
        # https://github.com/pysal/esda/blob/master/esda/moran.py#L925
        z_lag = SpatialStats::Utils::Lag.neighbor_average(weights, z)
        zp = z.map(&:positive?)
        lp = z_lag.map(&:positive?)

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

      private

      def stat_i
        raise NotImplementedError, 'method stat_i not defined'
      end

      def mc_i
        raise NotImplementedError, 'method mc_i not defined'
      end

      def w
        @w ||= weights.dense
      end

      def gen_rng(seed = nil)
        if seed
          Random.new(seed)
        else
          Random.new
        end
      end

      def neighbor_weights
        # record the non-zero weights in variable length arrays for each
        # row in the weights table
        ws = [[]] * weights.n
        (0..weights.n - 1).each do |idx|
          neighbors = []
          w[idx, true].each do |wij|
            neighbors << wij if wij != 0
          end
          ws[idx] = neighbors
        end
        ws
      end
    end
  end
end
