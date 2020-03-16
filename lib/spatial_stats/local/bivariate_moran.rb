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

      def i
        w = weights.full
        y_lag = SpatialStats::Utils::Lag.neighbor_average(w, y)
        x.each_with_index.map do |xi, idx|
          xi * y_lag[idx]
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
    end
  end
end
