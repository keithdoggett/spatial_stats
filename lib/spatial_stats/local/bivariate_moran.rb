# frozen_string_literal: true

module SpatialStats
  module Local
    class BivariateMoran < Stat
      def initialize(scope, x_field, y_field, weights)
        @scope = scope
        @x_field = x_field
        @y_field = y_field
        @weights = weights
      end
      attr_accessor :scope, :x_field, :y_field, :weights
      attr_writer :x, :y

      def i
        x.each_with_index.map do |_xi, idx|
          i_i(idx)
        end
      end

      def i_i(idx)
        x[idx] * y_lag[idx]
      end

      def mc(permutations = 99, seed = nil)
        rng = gen_rng(seed)
        shuffles = crand(y, permutations, rng)
        n = shuffles.size
        # r is the number of equal to or more extreme samples
        i_orig = i
        rs = [0] * i_orig.size

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

        # For each shuffle, we only need the spatially lagged variable
        # at one index, but it needs to be an array of length n.
        # Store a zeros array that can be mutated or duplicated and the
        # lagged variable at idx will only be set there.
        idx = 0
        while idx < n
          ii_orig = i_orig[idx]
          y_lag_i = (Numo::DFloat.cast(ws[idx]) * shuffles[idx]).sum(1)
          ii_new = x[idx] * y_lag_i

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
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @x_field)
                                               .standardize
      end

      def y
        @y ||= SpatialStats::Queries::Variables.query_field(@scope, @y_field)
                                               .standardize
      end

      private

      def y_lag
        @y_lag ||= SpatialStats::Utils::Lag.neighbor_sum(w, y)
      end
    end
  end
end
