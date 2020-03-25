# frozen_string_literal: true

module SpatialStats
  module Local
    class G < Stat
      def initialize(scope, field, weights, star = false)
        super(scope, field, weights)
        @star = star
      end
      attr_accessor :star
      attr_writer :x

      def i
        x.each_with_index.map do |_x_val, idx|
          i_i(idx)
        end
      end

      def i_i(idx)
        x_lag[idx] / denominators[idx]
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
      end
      alias z x

      def star?
        @star ||= w.trace.positive?
      end

      private

      def w
        @w ||= @weights.full
      end

      def x_lag
        # window if star is true
        if star?
          SpatialStats::Utils::Lag.window_average(w, x)
        else
          SpatialStats::Utils::Lag.neighbor_average(w, x)
        end
      end

      def denominators
        n = w.row_size
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
