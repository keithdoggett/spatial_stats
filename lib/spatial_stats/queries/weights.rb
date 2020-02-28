# frozen_string_literal: true

module SpatialStats
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  module ClassMethods
    def inverse_distance_weights_knn(scope, column, n, alpha)
      column = ActiveRecord::Base.connection.quote_column_name(column)
      neighbors = find_by_sql([<<-SQL, scope: scope, n: n])
      WITH scope as (:scope)
          SELECT neighbors.*
          FROM scope AS a
            CROSS JOIN LATERAL (
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
            ST_Distance(a.#{column}, b.#{column}) as distance
            FROM scope as b
            WHERE a.#{primary_key} <> b.#{primary_key}
            ORDER BY a.#{column} <-> b.#{column}
            LIMIT :n
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

      neighbors = neighbors.group_by(&:i_id)
      neighbors.transform_values do |val|
        # val is array of neighbors
        val.map! do |record|
          data = record.as_json.symbolize_keys
          data[:weight] = 1.0 / ((scale * data[:distance])**alpha)
          data
        end
      end
    end

    def inverse_distance_weights_band(scope, column, bandwidth, alpha = 1)
      column = ActiveRecord::Base.connection.quote_column_name(column)
      neighbors = find_by_sql([<<-SQL, scope: scope, bandwidth: bandwidth])
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

      neighbors = neighbors.group_by(&:i_id)
      neighbors.transform_values do |val|
        # val is array of neighbors
        val.map! do |record|
          data = record.as_json.symbolize_keys
          data[:weight] = 1.0 / ((scale * data[:distance])**alpha)
          data
        end
      end
    end

    def knn(scope, column, n)
      column = ActiveRecord::Base.connection.quote_column_name(column)
      neighbors = find_by_sql([<<-SQL, scope: scope, n: n])
      WITH scope as (:scope)
          SELECT neighbors.*
          FROM scope AS a
            CROSS JOIN LATERAL (
            SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id
            FROM scope as b
            WHERE a.#{primary_key} <> b.#{primary_key}
            ORDER BY a.#{column} <-> b.#{column}
            LIMIT :n
          ) AS neighbors
      SQL
      neighbors.group_by(&:i_id).transform_values { |v| v.map(&:j_id) }
    end

    def distance_band_neighbors(scope, column, distance)
      column = ActiveRecord::Base.connection.quote_column_name(column)
      neighbors = find_by_sql([<<-SQL, scope: scope, distance: distance])
        WITH neighbors AS (
          WITH scope AS (:scope)
          SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
          ST_DWithin(a.#{column}, b.#{column}, :distance) as is_neighbor
          FROM scope as a, scope as b
          ORDER BY i_id
        )
        SELECT * FROM neighbors WHERE is_neighbor = 't' AND i_id <> j_id
      SQL
      neighbors.group_by(&:i_id).transform_values { |v| v.map(&:j_id) }
    end

    # DE-9IM queen contiguiety = F***T****
    def queen_contiguity_neighbors(scope, column)
      _contiguity_neighbors(scope, column, 'F***T****')
    end

    def rook_contiguity_neighbors(scope, column)
      _contiguity_neighbors(scope, column, 'F***1****')
    end

    def _contiguity_neighbors(scope, column, pattern)
      column = ActiveRecord::Base.connection.quote_column_name(column)
      neighbors = find_by_sql([<<-SQL, scope: scope])
        WITH neighbors AS (
          WITH scope AS (:scope)
          SELECT a.#{primary_key} as i_id, b.#{primary_key} as j_id,
          ST_RELATE(a.#{column}, b.#{column}, \'#{pattern}\') as is_neighbor
          FROM scope as a, scope as b
          ORDER BY i_id
        )
        SELECT * FROM neighbors WHERE is_neighbor = 't'
      SQL
      neighbors.group_by(&:i_id).transform_values { |v| v.map(&:j_id) }
    end
  end
end
