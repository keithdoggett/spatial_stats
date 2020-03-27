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

      def x_lag
        # window if star is true
        @x_lag ||= begin
          if star?
            SpatialStats::Utils::Lag.window_sum(w, x)
          else
            SpatialStats::Utils::Lag.neighbor_sum(w, x)
          end
        end
      end

      def denominators
        @denominators ||= begin
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
end
