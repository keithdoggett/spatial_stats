# frozen_string_literal: true

module SpatialStats
  module Local
    ##
    # BivariateMoran computes the local correlation between a variable x and
    # spatially lagged variable y.
    class BivariateMoran < Stat
      ##
      # A new instance of BivariateMoran
      #
      # @param [ActiveRecord::Relation] scope
      # @param [Symbol, String] x_field to query from scope
      # @param [Symbol, String] y_field to query from scope
      # @param [WeightsMatrix] weights to define relationship between observations in scope
      #
      # @return [Moran]
      def initialize(scope, x_field, y_field, weights)
        @scope = scope
        @x_field = x_field
        @y_field = y_field
        @weights = weights.standardize
      end
      attr_accessor :scope, :x_field, :y_field, :weights

      ##
      # Computes the local indicator of spatial correlation for
      # x against lagged y.
      #
      # @return [Array] of correlations for each observation.
      def stat
        x.each_with_index.map do |_xi, idx|
          stat_i(idx)
        end
      end
      alias i stat

      ##
      # Computes Bivariate Moran's I at a single index. Multiplies x at
      # this index by the lagged y value at this index.
      #
      # @param [Integer] idx to perfrom the calculation on
      #
      # @return [Float] correlation at idx
      def stat_i(idx)
        x[idx] * y_lag[idx]
      end

      ##
      # Permutation test to determine a pseudo p-values of the +#stat+ method.
      # Shuffles y values, hold x values, recomputes +#stat+ for each variation,
      # then compares to the computed one. The ratio of more extreme values to
      # permutations is returned for each observation.
      #
      # @see https://geodacenter.github.io/glossary.html#perm
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Array] of p-values
      def mc(permutations = 99, seed = nil)
        mc_bv(permutations, seed)
      end

      ##
      # Determines what quadrant an observation is in. Based on its value
      # compared to its neighbors. This does not work for all stats, since
      # it requires that values be negative.
      #
      # In a standardized array of z, high values are values greater than 0
      # and it's neighbors are determined by the spatial lag and if that is
      # positive then it's neighbors would be high, low otherwise.
      #
      # Quadrants are:
      # [HH] a high value surrounded by other high values
      # [LH] a low value surrounded by high values
      # [LL] a low value surrounded by low values
      # [HL] a high value surrounded by low values
      #
      # @return [Array] of labels
      def quads
        # https://github.com/pysal/esda/blob/master/esda/moran.py#L925
        z_lag = SpatialStats::Utils::Lag.neighbor_average(weights, y)
        zp = x.map(&:positive?)
        lp = z_lag.map(&:positive?)

        # hh = zp & lp
        # lh = zp ^ true & lp
        # ll = zp ^ true & lp ^ true
        # hl = zp next to lp ^ true
        hh = zp.each_with_index.map { |v, idx| v & lp[idx] }
        lh = zp.each_with_index.map { |v, idx| (v ^ true) & lp[idx] }
        ll = zp.each_with_index.map { |v, idx| (v ^ true) & (lp[idx] ^ true) }
        hl = zp.each_with_index.map { |v, idx| v & (lp[idx] ^ true) }

        # now zip lists and map them to proper terms
        quad_terms = %w[HH LH LL HL]
        hh.zip(lh, ll, hl).map do |feature|
          quad_terms[feature.index(true)]
        end
      end
      alias groups quads

      ##
      # Summary of the statistic. Computes +stat+, +mc+, and +groups+ then returns the values
      # in a hash array.
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Array]
      def summary(permutations = 99, seed = nil)
        p_vals = mc(permutations, seed)
        data = weights.keys.zip(stat, p_vals, groups)
        data.map do |row|
          { key: row[0], stat: row[1], p: row[2], group: row[3] }
        end
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @x_field)
                                               .standardize
      end

      def y
        @y ||= SpatialStats::Queries::Variables.query_field(@scope, @y_field)
                                               .standardize
      end

      private

      def mc_i(wi, perms, idx)
        y_lag_i = (wi * perms).sum(1)
        x[idx] * y_lag_i
      end

      def mc_observation_calc(stat_i_orig, stat_i_new, _permutations)
        # Since moran can be positive or negative, go by this definition
        if stat_i_orig.positive?
          (stat_i_new >= stat_i_orig).count
        else
          (stat_i_new <= stat_i_orig).count
        end
      end

      def y_lag
        @y_lag ||= SpatialStats::Utils::Lag.neighbor_sum(weights, y)
      end
    end
  end
end
