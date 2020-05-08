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
      # @param [Hash] weights hash of format +{key: [{id: neighbor_key, weight: 1}]}+ that describe the relations between neighbors
      #
      # @return [WeightsMatrix]
      def initialize(weights)
        @weights = weights
        @keys = weights.keys
        @n = keys.size
      end
      attr_accessor :keys, :weights, :n

      ##
      # Compute the n x n Numo::Narray of the weights hash.
      #
      # @example
      #   hash = {1 => [{id: 2, weight: 1}], 2 => [{id: 1, weight: 1},
      #       {id: 3, weight: 1}], 3 => [{id: 2, weight: 1}]}
      #   wm = WeightsMatrix.new(hash.keys, hash)
      #   wm.full
      #   # => Numo::DFloat[[0, 1, 0], [1, 0, 1], [0, 1, 0]]
      #
      # @return [Numo::DFloat]
      def dense
        @dense ||= begin
          mat = Numo::DFloat.zeros(n, n)
          keys.each_with_index do |key, i|
            neighbors = weights[key]
            neighbors.each do |neighbor|
              j = keys.index(neighbor[:id])
              weight = neighbor[:weight]

              # assign the weight to row and column
              mat[i, j] = weight
            end
          end

          mat
        end
      end

      ##
      # Compute the CSR representation of the weights.
      #
      # @return [CSRMatrix]
      def sparse
        @sparse ||= CSRMatrix.new(dense.to_a.flatten, n, n)
      end

      ##
      # Compute the cardinalities of each neighbor into an array
      #
      # @return [Array]
      def wc
        @wc ||= begin
          row_index = sparse.row_index
          (0..n - 1).map do |idx|
            row_index[idx + 1] - row_index[idx]
          end
        end
      end

      ##
      # Row standardized version of the weights matrix.
      # Will return a new version of the weights matrix with standardized
      # weights.
      #
      # @return [WeightsMatrix]
      def standardize
        new_weights = weights

        new_weights.transform_values do |neighbors|
          sum = neighbors.reduce(0.0) { |acc, neighbor| acc + neighbor[:weight] }

          neighbors.map do |neighbor|
            hash = neighbor
            hash[:weight] /= sum
          end
        end

        self.class.new(new_weights)
      end

      ##
      # Windowed version of the weights matrix.
      # If a row already has an entry for itself, it will be skipped.
      #
      # @return [WeightsMatrix]
      def window
        new_weights = weights

        new_weights.each do |key, neighbors|
          unless neighbors.find { |neighbor| neighbor[:id] == key }
            new_neighbors = (neighbors << { id: key, weight: 1 })
            new_weights[key] = new_neighbors.sort_by { |neighbor| neighbor[:id] }
          end
        end

        self.class.new(new_weights)
      end
    end
  end
end
