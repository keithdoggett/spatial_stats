# frozen_string_literal: true

module SpatialStats
  module Global
    ##
    # Stat is the abstract base class for global stats.
    # It defines the methods that are common between all classes
    # and will raise a NotImplementedError on those that are specific
    # for each type of statistic.
    class Stat
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights.standardized
      end
      attr_accessor :scope, :field, :weights

      def stat
        raise NotImplementedError, 'method stat not defined'
      end

      ##
      # The expected value of +#stat+
      #
      # @return [Float]
      def expectation
        raise NotImplementedError, 'method expectation not implemented'
      end

      def variance
        raise NotImplementedError, 'method variance not implemented'
      end

      ##
      # Z-score of the statistic.
      #
      # @return [Float] the number of deviations from the mean
      def z_score
        (stat - expectation) / Math.sqrt(variance)
      end

      def mc(permutations, seed)
        rng = gen_rng(seed)
        shuffles = []
        permutations.times do
          shuffles << x.shuffle(random: rng)
        end
        shuffles = Numo::DFloat.cast(shuffles)

        # r is the number of equal to or more extreme samples
        # one sided
        stat_orig = stat.round(5)
        # r = 0

        # compute new stat values
        stat_new = stat_mc(shuffles)

        r = if stat_orig.positive?
              (stat_new >= stat_orig).count
            else
              (stat_new <= stat_orig).count
            end

        (r + 1.0) / (permutations + 1.0)
      end

      def mc_bv(permutations, seed)
        # in multivariate, hold x and shuffle y
        rng = gen_rng(seed)
        shuffles = []
        permutations.times do
          shuffles << y.shuffle(random: rng)
        end
        shuffles = Numo::DFloat.cast(shuffles)

        # r is the number of equal to or more extreme samples
        stat_orig = stat.round(5)
        stat_new = stat_mc(shuffles)

        r = if stat_orig.positive?
              (stat_new >= stat_orig).count
            else
              (stat_new <= stat_orig).count
            end

        (r + 1.0) / (permutations + 1.0)
      end

      private

      def stat_mc(_shuffles)
        raise NotImplementedError, 'private method stat_mc not defined'
      end

      def w
        @w ||= weights.dense
      end

      def gen_rng(seed)
        if seed
          Random.new(seed)
        else
          Random.new
        end
      end
    end
  end
end
