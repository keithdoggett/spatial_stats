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

      def i_i(_idx)
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

      def mc(permutations = 99, seed = nil)
        # For local tests, we need to shuffle the values
        # but for each item, hold its value in place and shuffle
        # its neighbors. Then we will only test for that item instead
        # of the entire set. This will be done for each item.
        rng = gen_rng(seed)
        shuffles = crand(x, permutations, rng)

        # r is the number of equal to or more extreme samples
        i_orig = i
        rs = [0] * i_orig.size

        # For each shuffle, we only need the spatially lagged variable
        # at one index, but it needs to be an array of length n.
        # Store a zeros array that can be mutated or duplicated and the
        # lagged variable at idx will only be set there.
        lagged = [0] * i_orig.size

        shuffles.each_with_index do |perms, idx|
          ii_orig = i_orig[idx]
          wi = w[idx, true] # current weight row
          perms.each do |perm|
            stat = self.class.new(scope, field, weights)
            stat.x = perm

            # avoids computing lag for entire data set
            # when we only care about one entry
            lagged_var = wi.dot(perm)
            z_lag = lagged.dup
            z_lag[idx] = lagged_var
            stat.z_lag = z_lag

            ii_new = stat.i_i(idx)

            # https://geodacenter.github.io/glossary.html#ppvalue
            # NOTE: this is inconsistent with the output from GeoDa
            # for local permutation tests, they seem to use greater than
            # not greater than or equal to. I'm going to go by the definition
            # in the glossary for now.
            if ii_orig.positive?
              rs[idx] += 1 if ii_new >= ii_orig
            else
              rs[idx] += 1 if ii_new <= ii_orig
            end
          end
        end

        rs.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
      end

      def mc_bv(permutations, seed)
        rng = gen_rng(seed)
        shuffles = crand(y, permutations, rng)

        # r is the number of equal to or more extreme samples
        i_orig = i
        rs = [0] * i_orig.size
        shuffles.each_with_index do |perms, idx|
          ii_orig = i_orig[idx]
          perms.each do |perm|
            stat = self.class.new(@scope, @x_field, @y_field, @weights)
            stat.x = x
            stat.y = perm
            ii_new = stat.i_i(idx)

            if ii_orig.positive?
              rs[idx] += 1 if ii_new >= ii_orig
            else
              rs[idx] += 1 if ii_new <= ii_orig
            end
          end
        end

        rs.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
      end

      def quads
        # https://github.com/pysal/esda/blob/master/esda/moran.py#L925
        w = @weights.full
        z_lag = SpatialStats::Utils::Lag.neighbor_average(w, z)
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

      def w
        weights.standardized
      end

      def gen_rng(seed = nil)
        if seed
          Random.new(seed)
        else
          Random.new
        end
      end
    end
  end
end
