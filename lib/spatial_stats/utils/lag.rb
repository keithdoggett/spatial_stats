# frozen_string_literal: true

require 'matrix'
module SpatialStats
  module Utils
    module Lag
      # module for computing spatially lagged variables
      # from a weights matrix and variable array
      def self.neighbor_average(matrix, variables)
        matrix = matrix.row_standardized
        vec = Vector.elements(variables)
        (matrix * vec).to_a
      end

      def self.neighbor_sum(matrix, variables)
        vec = Vector.elements(variables)
        (matrix * vec).to_a
      end

      def self.window_average(matrix, variables)
        matrix = matrix.windowed.row_standardized
        vec = Vector.elements(variables)
        (matrix * vec).to_a
      end

      def self.window_sum(matrix, variables)
        matrix = matrix.windowed
        vec = Vector.elements(variables)
        (matrix * vec).to_a
      end
    end
  end
end
