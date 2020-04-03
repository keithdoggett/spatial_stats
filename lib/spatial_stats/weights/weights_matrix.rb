# frozen_string_literal: true

require 'numo/narray'

module SpatialStats
  module Weights
    ##
    # WeightsMatrix class is used to store spatial weights and related
    # information in various formats.
    class WeightsMatrix
      ##
      # A new instance of WeightsMatrix
      #
      # @param [Array] keys ordered list of keys used in weights
      # @param [Hash] weights hash of format +{key: [{j_id: neighbor_key, weight: 1}]}+ that describe the relations between neighbors
      #
      # @return [WeightsMatrix]
      def initialize(keys, weights)
        @keys = keys
        @weights = weights
        @n = keys.size
      end
      attr_accessor :keys, :weights, :n

      ##
      # Compute the n x n Numo::Narray of the weights hash.
      #
      # @example
      #   hash = {1 => [{j_id: 2, weight: 1}], 2 => [{j_id: 1, weight: 1},
      #       {j_id: 3, weight: 1}], 3 => [{j_id: 2, weight: 1}]}
      #   wm = WeightsMatrix.new(hash.keys, hash)
      #   wm.full
      #   # => Numo::DFloat[[0, 1, 0], [1, 0, 1], [0, 1, 0]]
      #
      # @return [Numo::DFloat]
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

      ##
      # Row standardized version of +#full+
      #
      # @return [Numo::DFloat]
      def standardized
        @standardized ||= full.row_standardized
      end
    end
  end
end
