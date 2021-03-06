# frozen_string_literal: true

module SpatialStats
  module Weights
    # Distant weights module includes methods that provide an interface to
    # distance-based weights queries and formats the result properly to utilize
    # a weights matrix.
    module Distant
      ##
      # Compute distance band weights matrix for a scope.
      #
      # @param [ActiveRecord::Relation] scope to query
      # @param [Symbol, String] field with geometry in it
      # @param [Numeric] bandwidth of distance band
      #
      # @return [WeightsMatrix]
      def self.distance_band(scope, field, bandwidth)
        neighbors = SpatialStats::Queries::Weights
                    .distance_band_neighbors(scope, field, bandwidth)

        # get keys to make sure we have consistent dimensions when
        # some entries don't have neighbors.
        # define a new hash that has all the keys from scope
        keys = SpatialStats::Queries::Variables.query_field(scope, scope.klass.primary_key)

        neighbors = neighbors.group_by(&:i_id)
        missing_neighbors = Hash[(keys - neighbors.keys).map { |key| [key, []] }]
        neighbors = neighbors.merge(missing_neighbors)

        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            hash = { id: neighbor[:j_id] }
            hash[:weight] = 1
            hash
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(weights)
      end

      ##
      # Compute distance band weights matrix for a scope.
      #
      # @param [ActiveRecord::Relation] scope to query
      # @param [Symbol, String] field with geometry in it
      # @param [Integer] k neighbors to find
      #
      # @return [WeightsMatrix]
      def self.knn(scope, field, k)
        neighbors = SpatialStats::Queries::Weights
                    .knn(scope, field, k)

        # get keys to make sure we have consistent dimensions when
        # some entries don't have neighbors.
        # define a new hash that has all the keys from scope
        keys = SpatialStats::Queries::Variables.query_field(scope, scope.klass.primary_key)

        neighbors = neighbors.group_by(&:i_id)
        missing_neighbors = Hash[(keys - neighbors.keys).map { |key| [key, []] }]
        neighbors = neighbors.merge(missing_neighbors)

        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            hash = { id: neighbor[:j_id] }
            hash[:weight] = 1
            hash
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(weights)
      end

      ##
      # Compute idw, distance band weights matrix for a scope.
      #
      # @param [ActiveRecord::Relation] scope to query
      # @param [Symbol, String] field with geometry in it
      # @param [Numeric] bandwidth of distance band
      # @param [Numeric] alpha used in weighting calculation (usually 1 or 2)
      #
      # @return [WeightsMatrix]
      def self.idw_band(scope, field, bandwidth, alpha = 1)
        neighbors = SpatialStats::Queries::Weights
                    .idw_band(scope, field, bandwidth, alpha)

        # get keys to make sure we have consistent dimensions when
        # some entries don't have neighbors.
        # define a new hash that has all the keys from scope
        keys = SpatialStats::Queries::Variables.query_field(scope, scope.klass.primary_key)
        neighbors = neighbors.group_by { |pair| pair[:i_id] }
        missing_neighbors = Hash[(keys - neighbors.keys).map { |key| [key, []] }]
        neighbors = neighbors.merge(missing_neighbors)

        # only keep j_id and weight
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            { weight: neighbor[:weight], id: neighbor[:j_id] }
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(weights)
      end

      ##
      # Compute idw, knn weights matrix for a scope.
      #
      # @param [ActiveRecord::Relation] scope to query
      # @param [Symbol, String] field with geometry in it
      # @param [Integer] k neighbors to find
      # @param [Numeric] alpha used in weighting calculation (usually 1 or 2)
      #
      # @return [WeightsMatrix]
      def self.idw_knn(scope, field, k, alpha = 1)
        neighbors = SpatialStats::Queries::Weights
                    .idw_knn(scope, field, k, alpha)

        # get keys to make sure we have consistent dimensions when
        # some entries don't have neighbors.
        # define a new hash that has all the keys from scope
        keys = SpatialStats::Queries::Variables.query_field(scope, scope.klass.primary_key)
        neighbors = neighbors.group_by { |pair| pair[:i_id] }
        missing_neighbors = Hash[(keys - neighbors.keys).map { |key| [key, []] }]
        neighbors = neighbors.merge(missing_neighbors)

        # only keep j_id and weight
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            { weight: neighbor[:weight], id: neighbor[:j_id] }
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(weights)
      end
    end
  end
end
