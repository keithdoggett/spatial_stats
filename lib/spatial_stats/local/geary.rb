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
        zs = Numo::DFloat.cast(z)
        zi = (z[idx] - zs)**2
        (w[idx, true] * zi).sum
      end

      def mc(permutations = 99, seed = nil)
        # For local tests, we need to shuffle the values
        # but for each item, hold its value in place and shuffle
        # its neighbors. Then we will only test for that item instead
        # of the entire set. This will be done for each item.
        rng = gen_rng(seed)
        shuffles = crand(x, permutations, rng)

        n = weights.n
        # r is the number of equal to or more extreme samples
        i_orig = i
        rs = [0] * i_orig.size

        # record the non-zero weights in variable length arrays for each
        # row in the weights table
        ws = [[]] * n
        (0..weights.n - 1).each do |idx|
          neighbors = []
          w[idx, true].each do |wij|
            neighbors << wij if wij != 0
          end
          ws[idx] = neighbors
        end

        # For each shuffle, we only need the spatially lagged variable
        # at one index, but it needs to be an array of length n.
        # Store a zeros array that can be mutated or duplicated and the
        # lagged variable at idx will only be set there.
        idx = 0
        while idx < n
          ii_orig = i_orig[idx]
          zi = (z[idx] - shuffles[idx])**2

          ii_new = (Numo::DFloat.cast(ws[idx]) * zi).sum(1)

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

      private

      def w
        @w ||= weights.full.row_standardized
      end
    end
  end
end
