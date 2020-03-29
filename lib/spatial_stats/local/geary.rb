# frozen_string_literal: true

module SpatialStats
  module Local
    class Geary < Stat
      def initialize(scope, field, weights)
        super(scope, field, weights)
      end
      attr_writer :x

      def i
        z.each_with_index.map do |_zi, idx|
          i_i(idx)
        end
      end

      def i_i(idx)
        n = w.shape[0]
        sum = 0
        (0..n - 1).each do |j|
          sum += w[idx, j] * ((z[idx] - z[j])**2)
        end
        sum
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

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

        shuffles.each_with_index do |perms, idx|
          ii_orig = i_orig[idx]
          perms.each do |perm|
            stat = self.class.new(scope, field, weights)
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

      private

      def w
        @w ||= weights.full.row_standardized
      end
    end
  end
end
