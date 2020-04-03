# frozen_string_literal: true

module SpatialStats
  module Queries
    ##
    # Weights includes methods for querying a scope using PostGIS sql methods
    # to determine neighbors and weights based on different weighting
    # schemes/formulas.
    module Weights
      ##
      # Compute inverse distance weighted, k nearest neighbors weights
      # for a given scope and geometry.
      #
      # Combines knn and idw weightings. Each observation will have
      # k neighbors, but the weights will be calculated by 1/(d**alpha).
      #
      # Only works for geometry types that implement ST_Distance.
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      # @param [Integer] k neighbors to find
      # @param [Integer] alpha number used in inverse calculations (usually 1 or 2)
      #
      # @return [Hash]
      def self.idw_knn(scope, column, k, alpha = 1)
        klass = scope.klass
        column = ActiveRecord::Base.connection.quote_column_name(column)
        primary_key = klass.quoted_primary_key
        neighbors = klass.find_by_sql([<<-SQL, scope: scope, k: k])
          WITH scope as (:scope)
          SELECT neighbors.*
          FROM scope AS a
            CROSS JOIN LATERAL (
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
            ST_Distance(a.#{column}, b.#{column}) as distance
            FROM scope as b
            WHERE a.#{primary_key} <> b.#{primary_key}
            ORDER BY a.#{column} <-> b.#{column}
            LIMIT :k
          ) AS neighbors
        SQL

        # if the lowest distance is <1, then we need to scale
        # every distance by the factor that makes the lowest 1
        min_dist = neighbors.map(&:distance).min
        scale = if min_dist < 1
                  1 / min_dist
                else
                  1
                end

        neighbors.map do |neighbor|
          # formula is 1/(d^alpha)
          weight = 1.0 / ((scale * neighbor.distance)**alpha)
          hash = neighbor.as_json.symbolize_keys
          hash[:weight] = weight
          hash
        end
      end

      ##
      # Compute inverse distance weighted, band limited weights
      # for a given scope and geometry.
      #
      # Combines distance_band and idw weightings. Each observation will have
      # neighbers in the bandwidth, but the weights will be calculated by 1/(d**alpha).
      #
      # Only works for geometry types that implement ST_Distance and ST_DWithin.
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      # @param [Numeric] bandwidth to find neighbors in
      # @param [Integer] alpha number used in inverse calculations (usually 1 or 2)
      #
      # @return [Hash]
      def self.idw_band(scope, column, bandwidth, alpha = 1)
        klass = scope.klass
        column = ActiveRecord::Base.connection.quote_column_name(column)
        primary_key = klass.quoted_primary_key
        neighbors = klass.find_by_sql([<<-SQL, scope: scope, bandwidth: bandwidth])
          WITH neighbors AS (
            WITH scope AS (:scope)
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
            ST_DWithin(a.#{column}, b.#{column}, :bandwidth) as is_neighbor,
            ST_Distance(a.#{column}, b.#{column}) as distance
            FROM scope as a, scope as b
            ORDER BY i_id
          )
          SELECT * FROM neighbors WHERE is_neighbor = 't' AND i_id <> j_id
        SQL

        # if the lowest distance is <1, then we need to scale
        # every distance by the factor that makes the lowest 1
        min_dist = neighbors.map(&:distance).min
        scale = if min_dist < 1
                  1 / min_dist
                else
                  1
                end

        neighbors.map do |neighbor|
          # formula is 1/(d^alpha)
          weight = 1.0 / ((scale * neighbor.distance)**alpha)
          hash = neighbor.as_json.symbolize_keys
          hash[:weight] = weight
          hash
        end
      end

      ##
      # Compute k nearest neighbor weights for a given scope.
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      # @param [Integer] k neighbors to find
      #
      # @return [Hash]
      def self.knn(scope, column, k)
        klass = scope.klass
        column = ActiveRecord::Base.connection.quote_column_name(column)
        primary_key = klass.quoted_primary_key
        klass.find_by_sql([<<-SQL, scope: scope, k: k])
          WITH scope as (:scope)
          SELECT neighbors.*
          FROM scope AS a
            CROSS JOIN LATERAL (
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id
            FROM scope as b
            WHERE a.#{primary_key} <> b.#{primary_key}
            ORDER BY a.#{column} <-> b.#{column}
            LIMIT :k
          ) AS neighbors
        SQL
      end

      ##
      # Compute distance band weights for a given scope. Identifies neighbors
      # as other observations in scope that are within the distance band
      # from the observation.
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      # @param [Numeric] bandwidth to find neighbors in
      #
      # @return [Hash]
      def self.distance_band_neighbors(scope, column, bandwidth)
        klass = scope.klass
        column = ActiveRecord::Base.connection.quote_column_name(column)
        primary_key = klass.quoted_primary_key
        klass.find_by_sql([<<-SQL, scope: scope, distance: bandwidth])
          WITH neighbors AS (
            WITH scope AS (:scope)
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
            ST_DWithin(a.#{column}, b.#{column}, :distance) as is_neighbor
            FROM scope as a, scope as b
            ORDER BY i_id
          )
          SELECT * FROM neighbors WHERE is_neighbor = 't' AND i_id <> j_id
        SQL
      end

      ##
      # Compute queen contiguity weights for a given scope. Queen
      # contiguity weights are defined by geometries sharing an edge
      # or vertex.
      #
      # DE-9IM pattern = +F***T****+
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      #
      # @return [Hash]
      def self.queen_contiguity_neighbors(scope, column)
        _contiguity_neighbors(scope, column, 'F***T****')
      end

      ##
      # Compute rook contiguity weights for a given scope. Rook
      # contiguity weights are defined by geometries sharing an edge.
      #
      # DE-9IM pattern = +'F***1****'+
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      #
      # @return [Hash]
      def self.rook_contiguity_neighbors(scope, column)
        _contiguity_neighbors(scope, column, 'F***1****')
      end

      ##
      # Generic function to compute contiguity neighbor weights for a
      # given scope. Takes any valid DE-9IM pattern and computes the
      # neighbors based off of that.
      #
      # @see https://en.wikipedia.org/wiki/DE-9IM
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] column that contains the geometry
      # @param [String] pattern to describe neighbor relation
      #
      # @return [Hash]
      def self._contiguity_neighbors(scope, column, pattern)
        klass = scope.klass
        column = ActiveRecord::Base.connection.quote_column_name(column)
        primary_key = klass.quoted_primary_key
        klass.find_by_sql([<<-SQL, scope: scope])
          WITH neighbors AS (
            WITH scope AS (:scope)
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
            ST_RELATE(a.#{column}, b.#{column}, \'#{pattern}\') as is_neighbor
            FROM scope as a, scope as b
            ORDER BY i_id
          )
          SELECT * FROM neighbors WHERE is_neighbor = 't'
        SQL
      end
    end
  end
end
