# frozen_string_literal: true

module SpatialStats
  module Local
    ##
    # Geary's C statistic computes the spatial lag of the difference between
    # variable zi and it's neighbors squared, in the set z. The local version
    # returns a value for each entry.
    class Geary < Stat
      ##
      # A new instance of Geary
      #
      # @param [ActiveRecord::Relation] scope
      # @param [Symbol, String] field to query from scope
      # @param [WeightsMatrix] weights to define relationship between observations in scope
      #
      # @return [Geary]
      def initialize(scope, field, weights)
        super(scope, field, weights)
      end

      ##
      # Computes Geary's C for every observation in the +scoe+.
      # Geary's C is defined as the square distance between
      # an observation and it's neighbors, factored to their weights.
      #
      # @return [Array] the C value for each observation
      def stat
        z.each_with_index.map do |_zi, idx|
          stat_i(idx)
        end
      end
      alias c stat

      ##
      # Values of the +field+ queried from the +scope+
      #
      # @return [Array]
      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

      private

      def stat_i(idx)
        zs = Numo::DFloat.cast(z)
        zi = (z[idx] - zs)**2
        (w[idx, true] * zi).sum
      end

      def mc_i(wi, perms, idx)
        zi = (z[idx] - perms)**2
        (wi * zi).sum(1)
      end

      def w
        @w ||= weights.full.row_standardized
      end
    end
  end
end
