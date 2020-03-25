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
        # conditional randomization method
        # will generate an n x permutations array of arrays.
        # For each n, i will be held the same and the values around it will
        # be permutated.
        arr.each_with_index.map do |xi, idx|
          tmp_arr = arr.dup
          tmp_arr.delete_at(idx)
          permutations.times.map do
            perm = tmp_arr.shuffle(random: rng)
            perm.insert(idx, xi)
          end
        end
      end

      def mc(permutations, seed)
        # For local tests, we need to shuffle the values
        # but for each item, hold its value in place and shuffle
        # its neighbors. Then we will only test for that item instead
        # of the entire set. This will be done for each item.
        rng = gen_rng(seed)
        shuffles = crand(x, permutations, rng)

        # r is the number of equal to or more extreme samples
        i_orig = i
        rs = [0] * i_orig.size
        shuffles.each_with_index do |perms, idx|
          stat = self.class.new(scope, field, weights)
          ii_orig = i_orig[idx]
          perms.each do |perm|
            stat.x = perm
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
          stat = self.class.new(@scope, @x_field, @y_field, @weights)
          ii_orig = i_orig[idx]
          perms.each do |perm|
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

      private

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
