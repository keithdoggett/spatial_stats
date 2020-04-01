# frozen_string_literal: true

module SpatialStats
  module Local
    class GetisOrd < Stat
      def initialize(scope, field, weights, star = false)
        super(scope, field, weights)
        @star = star
      end
      attr_accessor :star

      def stat
        x.each_with_index.map do |_x_val, idx|
          stat_i(idx)
        end
      end
      alias g stat

      def stat_i(idx)
        x_lag[idx] / denominators[idx]
      end

      def mc_i(wi, perms, idx)
        x_lag_i = (wi * perms).sum(1)
        x_lag_i / denominators[idx]
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
