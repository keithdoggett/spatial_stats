# frozen_string_literal: true

module SpatialStats
  module Local
    class G < Stat
      def initialize(scope, field, weights, star = false)
        super(scope, field, weights)
        @star = star
      end
      attr_accessor :star
      attr_writer :x, :z_lag

      def i
        x.each_with_index.map do |_x_val, idx|
          i_i(idx)
        end
      end

      def i_i(idx)
        x_lag[idx] / denominators[idx]
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
          x_lag_i = (Numo::DFloat.cast(ws[idx]) * shuffles[idx]).sum(1)
          ii_new =  x_lag_i / denominators[idx]

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
      end
      alias z x

      def star?
        @star ||= weights.full.trace.positive?
      end

      private

      def w
        @w ||= begin
          if star?
            # TODO: try to fix this because it will still likely be a
            # bottleneck in mc testing
            weights.full.windowed.row_standardized
          else
            weights.standardized
          end
        end
      end

      def z_lag
        # window if star is true
        @z_lag ||= begin
          if star?
            SpatialStats::Utils::Lag.window_sum(w, x)
          else
            SpatialStats::Utils::Lag.neighbor_sum(w, x)
          end
        end
      end
      alias x_lag z_lag

      def denominators
        @denominators ||= begin
          n = w.shape[0]
          if star?
            [x.sum] * n
          else
            # add everything but i
            (0..n - 1).each.map do |idx|
              terms = x.dup
              terms.delete_at(idx)
              terms.sum
            end
          end
        end
      end
    end
  end
end
