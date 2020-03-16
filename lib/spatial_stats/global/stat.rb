# frozen_string_literal: true

module SpatialStats
  module Global
    class Stat
      # Base class for global stats
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_accessor :scope, :field, :weights

      def i
        raise NotImplementedError, 'method i not defined'
      end

      def expectation
        raise NotImplementedError, 'method expectation not implemented'
      end

      def variance
        raise NotImplementedError, 'method variance not implemented'
      end

      def z_score
        (i - expectation) / Math.sqrt(variance)
      end
    end
  end
end
