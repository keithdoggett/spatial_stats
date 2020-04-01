# frozen_string_literal: true

module SpatialStats
  module Global
    class Stat
      # Base class for global stats
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_accessor :scope, :field, :weights

      def stat
        raise NotImplementedError, 'method stat not defined'
      end

      def expectation
        raise NotImplementedError, 'method expectation not implemented'
      end

      def variance
        raise NotImplementedError, 'method variance not implemented'
      end

      def z_score
        (stat - expectation) / Math.sqrt(variance)
      end

      def mc(permutations, seed)
        rng = gen_rng(seed)
        shuffles = []
        permutations.times do
          shuffles << x.shuffle(random: rng)
        end
        # r is the number of equal to or more extreme samples
        # one sided
        stat_orig = stat
        r = 0
        shuffles.each do |shuffle|
          klass = self.class.new(@scope, @field, @weights)
          klass.x = shuffle

          # https://geodacenter.github.io/glossary.html#ppvalue
          if stat_orig.positive?
            r += 1 if klass.stat >= stat_orig
          else
            r += 1 if klass.stat <= stat_orig
          end
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

        # r is the number of equal to or more extreme samples
        stat_orig = stat
        r = 0
        shuffles.each do |shuffle|
          klass = self.class.new(@scope, @x_field, @y_field, @weights)
          klass.x = x
          klass.y = shuffle

          if stat_orig.positive?
            r += 1 if klass.stat >= stat_orig
          else
            r += 1 if klass.stat <= stat_orig
          end
        end

        (r + 1.0) / (permutations + 1.0)
      end

      private

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
