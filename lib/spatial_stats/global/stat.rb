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

      def i
        raise NotImplementedError, 'method i not defined'
      end

      def expectation
        raise NotImplementedError, 'method expectation not implemented'
      end

      def variance
        raise NotImplementedError, 'method variance not implemented'
      end

      def z_score
        (i - expectation) / Math.sqrt(variance)
      end

      def mc(permutations, seed)
        rng = gen_rng(seed)
        shuffles = []
        permutations.times do
          shuffles << x.shuffle(random: rng)
        end

        # r is the number of equal to or more extreme samples
        # one sided
        i_orig = i
        r = 0
        shuffles.each do |shuffle|
          stat = self.class.new(@scope, @field, @weights)
          stat.x = shuffle

          # https://geodacenter.github.io/glossary.html#ppvalue
          if i_orig.positive?
            r += 1 if stat.i >= i_orig
          else
            r += 1 if stat.i <= i_orig
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
        i_orig = i
        r = 0
        shuffles.each do |shuffle|
          stat = self.class.new(@scope, @x_field, @y_field, @weights)
          stat.x = x
          stat.y = shuffle

          if i_orig.positive?
            r += 1 if stat.i >= i_orig
          else
            r += 1 if stat.i <= i_orig
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
