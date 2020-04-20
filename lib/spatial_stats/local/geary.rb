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
        # TODO: maybe don't even use stat_i
        # just form all of the modified zs and then
        # pass it to a loop of mulvec all implemented in c ext
        zi = z.map { |val| (z[idx] - val)**2 }
        weights.sparse.dot_row(zi, idx)
      end

      def mc_i(wi, perms, idx)
        zi = (z[idx] - perms)**2
        (wi * zi).sum(1)
      end

      def mc_observation_calc(stat_i_orig, stat_i_new, _permutations)
        # Geary cannot be negative, so we have to use this technique from
        # GeoDa to determine p values. Note I slightly modified it to be inclusive
        # on both tails not just the lower tail.
        # https://github.com/GeoDaCenter/geoda/blob/master/Explore/LocalGearyCoordinator.cpp#L981        mean = stat_i_new.mean
        mean = stat_i_new.mean
        if stat_i_orig <= mean
          (stat_i_new <= stat_i_orig).count
        else
          (stat_i_new >= stat_i_orig).count
        end
      end
    end
  end
end
