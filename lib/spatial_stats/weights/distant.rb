# frozen_string_literal: true

module SpatialStats
  module Weights
    module Distant
      def self.distance_band(scope, field, bandwidth)
        p_key = scope.primary_key
        keys = scope.pluck(p_key)

        neighbors = SpatialStats::Queries::Weights
                    .distance_band_neighbors(scope, field, bandwidth)

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

      def self.knn(scope, field, n)
        p_key = scope.primary_key
        keys = scope.pluck(p_key)

        neighbors = SpatialStats::Queries::Weights
                    .knn(scope, field, n)

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

      def self.idw_band(scope, field, bandwidth, alpha = 1)
        p_key = scope.primary_key
        keys = scope.pluck(p_key)

        neighbors = SpatialStats::Queries::Weights
                    .idw_band(scope, field, bandwidth, alpha)
        neighbors = neighbors.group_by { |pair| pair[:i_id] }

        # only keep j_id and weight
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            { weight: neighbor[:weight], j_id: neighbor[:j_id] }
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(keys, weights)
      end

      def self.idw_knn(scope, field, n, alpha = 1)
        p_key = scope.primary_key
        keys = scope.pluck(p_key)

        neighbors = SpatialStats::Queries::Weights
                    .idw_knn(scope, field, n, alpha)
        neighbors = neighbors.group_by { |pair| pair[:i_id] }

        # only keep j_id and weight
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            { weight: neighbor[:weight], j_id: neighbor[:j_id] }
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(keys, weights)
      end
    end
  end
end
