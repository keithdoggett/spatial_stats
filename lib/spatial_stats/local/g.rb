# frozen_string_literal: true

module SpatialStats
  module Local
    class G < Stat
      def initialize(scope, field, weights, star = false)
        super(scope, field, weights)
        @star = star
      end
      attr_accessor :star

      def i
        # window if star is true
        w = weights.full
        x_lag = if star?
                  SpatialStats::Utils::Lag.window_average(w, x)
                else
                  SpatialStats::Utils::Lag.neighbor_average(w, x)
                end
        n = w.row_size

        denominators = if star?
                         [x.sum] * n
                       else
                         # add everything but i
                         (0..n - 1).each.map do |idx|
                           terms = x.dup
                           terms.delete_at(idx)
                           terms.sum
                         end
                       end

        x_lag.each_with_index.map do |numerator, idx|
          numerator / denominators[idx]
        end
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
      end
      alias z x

      def star?
        @star ||= @weights.full.trace.positive?
      end
    end
  end
end
