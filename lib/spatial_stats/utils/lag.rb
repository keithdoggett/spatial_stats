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
      # @param [Numo::NArray] matrix 2-D square matrix.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.neighbor_average(matrix, variables)
        matrix = matrix.row_standardized
        neighbor_sum(matrix, variables)
      end

      ##
      # Dot product of the input matrix by the input vector, variables.
      #
      # @param [Numo::NArray] matrix 2-D square matrix.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.neighbor_sum(matrix, variables)
        matrix.dot(variables).to_a
      end

      ##
      # Dot product of the input windowed, row standardizd matrix by
      # the input vector, variables.
      #
      # @param [Numo::NArray] matrix 2-D square matrix.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.window_average(matrix, variables)
        matrix = matrix.windowed.row_standardized
        window_sum(matrix, variables)
      end

      ##
      # Dot product of the input windowed matrix by
      # the input vector, variables.
      #
      # @param [Numo::NArray] matrix 2-D square matrix.
      # @param [Array] variables vector multiplying the matrix
      #
      # @return [Array] resultant vector
      def self.window_sum(matrix, variables)
        matrix = matrix.windowed
        matrix.dot(variables).to_a
      end
    end
  end
end
