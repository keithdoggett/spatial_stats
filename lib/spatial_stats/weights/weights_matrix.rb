# frozen_string_literal: true

require 'numo/narray'

module SpatialStats
  module Weights
    class WeightsMatrix
      def initialize(keys, weights)
        @keys = keys
        @weights = weights
        @n = keys.size
      end
      attr_accessor :keys, :weights, :n

      def full
        # returns a square matrix Wij using @keys as the order of items
        @full ||= begin
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

          Numo::DFloat.cast(rows)
        end
      end

      def standardized
        @standardized ||= full.row_standardized
      end
    end
  end
end
