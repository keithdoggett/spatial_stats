# frozen_string_literal: true

module SpatialStats
  module Weights
    ##
    # Contiguous weights module includes methods that provide an interface to
    # coniguous weights queries and formats the result properly to utilize
    # a weights matrix.
    module Contiguous
      ##
      # Compute rook weights matrix for a scope.
      #
      # @param [ActiveRecord::Relation] scope to query
      # @param [Symbol, String] field with geometry in it
      #
      # @return [WeightsMatrix]
      def self.rook(scope, field)
        neighbors = SpatialStats::Queries::Weights
                    .rook_contiguity_neighbors(scope, field)

        # get keys to make sure we have consistent dimensions when
        # some entries don't have neighbors.
        # define a new hash that has all the keys from scope
        keys = SpatialStats::Queries::Variables.query_field(scope, scope.klass.primary_key)
        hash = Hash[keys.map { |k| [k, []] }]

        neighbors = hash.merge(neighbors.group_by(&:i_id))
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
      # Compute queen weights matrix for a scope.
      #
      # @param [ActiveRecord::Relation] scope to query
      # @param [Symbol, String] field with geometry in it
      #
      # @return [WeightsMatrix]
      def self.queen(scope, field)
        neighbors = SpatialStats::Queries::Weights
                    .queen_contiguity_neighbors(scope, field)

        # get keys to make sure we have consistent dimensions when
        # some entries don't have neighbors.
        # define a new hash that has all the keys from scope
        keys = SpatialStats::Queries::Variables.query_field(scope, scope.klass.primary_key)
        hash = Hash[keys.map { |k| [k, []] }]

        neighbors = hash.merge(neighbors.group_by(&:i_id))
        weights = neighbors.transform_values do |value|
          value.map do |neighbor|
            hash = { id: neighbor[:j_id] }
            hash[:weight] = 1
            hash
          end
        end
        SpatialStats::Weights::WeightsMatrix.new(weights)
      end
    end
  end
end
