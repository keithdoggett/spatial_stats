# frozen_string_literal: true

module SpatialStats
  module Local
    class G
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_accessor :scope, :field, :weights, :star

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

      def quads
        # https://github.com/pysal/esda/blob/master/esda/moran.py#L925
        w = @weights.full
        z_lag = SpatialStats::Utils::Lag.neighbor_average(w, x)
        zp = x.map { |v| v > 0 }
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

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
      end

      def star?
        @star ||= @weights.full.trace.positive?
      end
    end
  end
end
