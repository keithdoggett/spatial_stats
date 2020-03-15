# frozen_string_literal: true

module SpatialStats
  module Local
    class MultivariateGeary
      def initialize(scope, fields, weights)
        @scope = scope
        @fields = fields
        @weights = weights
      end
      attr_accessor :scope, :fields, :weights

      def i
        m = fields.size
        gearys = fields.map do |field|
          Geary.new(scope, field, weights).i
        end
        gearys.transpose.map { |x| x.reduce(:+) / m }
      end
    end
  end
end
