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

      def mc_i(wi, perms, idx)
        y_lag_i = (wi * perms).sum(1)
        x[idx] * y_lag_i
      end

      def mc(permutations = 99, seed = nil)
        mc_bv(permutations, seed)
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
