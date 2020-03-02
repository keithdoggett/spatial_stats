# frozen_string_literal: true

require 'matrix'

module SpatialStats
  module Weights
    class WeightsMatrix
      def initialize(keys, weights)
        @keys = keys
        @weights = weights
      end
      attr_accessor :keys, :weights

      def full
        # returns a square matrix Wij using @keys as the order of items
        rows = []
        @keys.each do |i|
          # iterate through each key to get the data for the row
          row = @keys.map do |j|
            neighbors = @weights[i]
            match = neighbors.find { |neighbor| neighbor[:j_id] == j }
            if match
              match[:weight]
            else
              0
            end
          end
          rows << row
        end

        Matrix.rows(rows)
      end
    end
  end
end
