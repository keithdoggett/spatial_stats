# frozen_string_literal: true

require 'numo/narray'
module SpatialStats
  module Utils
    ##
    # Lag includes methdos for computing spatially lagged variables under
    # different contexts.
    module Lag
      ##
      # Dot product of the row_standardized input matrix
      # by the input vector, variables.
      #
      # @param [WeightsMatrix] matrix holding target weights.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.neighbor_average(matrix, variables)
        matrix = matrix.standardize
        neighbor_sum(matrix, variables)
      end

      ##
      # Dot product of the input matrix by the input vector, variables.
      #
      # @param [WeightsMatrix] matrix holding target weights.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.neighbor_sum(matrix, variables)
        matrix.sparse.mulvec(variables)
      end

      ##
      # Dot product of the input windowed, row standardized matrix by
      # the input vector, variables.
      #
      # @param [WeightsMatrix] matrix holding target weights.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.window_average(matrix, variables)
        matrix = matrix.window.standardize
        window_sum(matrix, variables)
      end

      ##
      # Dot product of the input windowed matrix by
      # the input vector, variables.
      #
      # @param [WeightsMatrix] matrix holding target weights.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.window_sum(matrix, variables)
        matrix = matrix.window
        matrix.sparse.mulvec(variables)
      end
    end
  end
end
