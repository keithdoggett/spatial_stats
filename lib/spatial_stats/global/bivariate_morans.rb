# frozen_string_literal: true

# https://geodacenter.github.io/workbook/5b_global_adv/lab5b.html
module SpatialStats
  module Global
    class BivariateMorans
      def initialize(scope, x, y, weights)
        @scope = scope
        @x = x
        @y = y
        @weights = weights
      end

      def x_vars
        @x_vars ||= SpatialStats::Queries::Variables
                    .query_field(@scope, @x).standardize
      end

      def y_vars
        @y_vars ||= SpatialStats::Queries::Variables
                    .query_field(@scope, @y).standardize
      end
    end
  end
end
