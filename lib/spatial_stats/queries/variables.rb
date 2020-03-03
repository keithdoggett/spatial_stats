# frozen_string_literal: true

module SpatialStats
  module Queries
    module Variables
      # Module to query for the desired variable from the given scope
      # and include the primary keys so that the weights matrix
      # will know that its keys will match up with the variables.
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
