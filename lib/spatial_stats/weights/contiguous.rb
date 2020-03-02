# frozen_string_literal: true

module SpatialStats
  module Weights
    module Contiguous
      def self.rook_weights(scope, column)
        p_key = scope.primary_key
        keys = scope.pluck(p_key)

        neighbors = SpatialStats::Queries::Weights
                    .rook_contiguity_neighbors(scope, column)

        neighbors = neighbors.group_by(&:i_id)
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            hash = neighbor.as_json(only: [:j_id]).symbolize_keys
            hash[:weight] = 1
            hash
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(keys, weights)
      end

      def self.queen_weights(scope, column)
        p_key = scope.primary_key
        keys = scope.pluck(p_key)

        neighbors = SpatialStats::Queries::Weights
                    .queen_contiguity_neighbors(scope, column)

        neighbors = neighbors.group_by(&:i_id)
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            hash = neighbor.as_json(only: [:j_id]).symbolize_keys
            hash[:weight] = 1
            hash
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(keys, weights)
      end
    end
  end
end
