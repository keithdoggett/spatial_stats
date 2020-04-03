# frozen_string_literal: true

module SpatialStats
  module Queries
    ##
    # Variables includes a method to query a field from a given scope and
    # keep it in a consistent order with how weights are queried.
    module Variables
      ##
      # Query the given field for a scope and order by primary key
      #
      # @example
      #   scope = County.all
      #   field = :avg_income
      #   SpatialStats::Queries::Variables.query_field(scope, field)
      #   # => [30023, 23400, 57800, ...]
      #
      # @param [ActiveRecord::Relation] scope you want to query
      # @param [Symbol, String] field you want to query from the scope
      #
      # @return [Array]
      def self.query_field(scope, field)
        klass = scope.klass
        column = ActiveRecord::Base.connection.quote_column_name(field)
        primary_key = klass.quoted_primary_key
        variables = klass.find_by_sql([<<-SQL, scope: scope])
          WITH scope as (:scope)
          SELECT scope.#{column} as field FROM scope
          ORDER BY scope.#{primary_key} ASC
        SQL
        variables.map(&:field)
      end
    end
  end
end
