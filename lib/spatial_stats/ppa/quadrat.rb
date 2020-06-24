# frozen_string_literal: true

module SpatialStats
  module PPA
    class PointPattern
      def mc_quadrat(x_regions, y_regions, permutations = 99, seed = nil)
        quad = Quadrat.new(self, bbox, x_regions, y_regions)
        quad.mc(permutations, seed)
      end
    end

    class Quadrat
      def initialize(pp, bbox, x_regions, y_regions)
        @pp = pp
        @bbox = bbox
        @x_regions = x_regions
        @y_regions = y_regions
        @m = x_regions * y_regions
      end
      attr_reader :pp, :bbox, :x_regions, :y_regions, :m

      ##
      # Degrees of freedom of the dataset
      #
      # @returns [Integer]
      def df
        m - 1
      end

      ##
      # Compute the expected value of each quadrat based on the
      # poisson CSR process for the region
      #
      # @returns [Float]
      def expectation
        pp.n / m.to_f
      end

      ##
      # Determine the number of points in each quadrat
      #
      # @returns [Array] integer array of size m
      def quadrat_counts(points = nil)
        points = pp.points if points.nil?
        quadrats = Array.new(m, 0)
        points.each do |point|
          q_idx = point_quadrat(point)
          quadrats[q_idx] += 1
        end
        quadrats
      end

      ##
      # Compute Pearson's +chi2+ goodness of fit statistic
      # for the distribution of points in the quadrats
      #
      # A value >1 indicates clustering and a value <1 indicates
      # dispersion
      #
      # @returns [Float]
      def chi2
        ni = quadrat_counts
        df * ni.sample_variance / expectation
      end

      ##
      # Permutation test to determine the probability of the chi2 value
      # of the PointPattern given this Quadrat.
      #
      # Compares the PointPattern to a CSR in these quadrats and
      # returns the proportion of simulated chi2 values greater than
      # the chi2 value for this PointPattern.
      #
      # @param [Integer] permutations, usually a multiple of 50 minus 1
      # @param [Number] seed for random number generator
      #
      # @returns [Float] psuedo p_value
      def mc(permutations = 99, seed = nil)
        Kernel.srand(seed) unless seed.nil?

        chi2_vals = []
        unif_dist = Rubystats::UniformDistribution.new(0, m)
        permutations.times do
          # Instead of simulating point processes, we can just do a uniform
          # distribution over m quadrats because they are all even size and
          # thus have an equal chance of being selected by a CSR.
          sim_quadrats = Array.new(m, 0)
          pp.n.times do
            sim_quadrats[unif_dist.rng.floor] += 1
          end

          sim_chi2 = df * sim_quadrats.sample_variance / expectation
          chi2_vals << sim_chi2
        end

        orig_chi2 = chi2
        r = chi2_vals.count { |val| val >= orig_chi2 }

        (r + 1.0) / (permutations + 1.0)
      end

      private

      ##
      # Determine which quadrat a point falls in
      #
      # Strategy is to divide the x and y regions into bins
      # then find which bin the pont falls in, in each direction.
      #
      # The quadrat is indexed as starting at the bottom left corner
      # then moving right, then up a row. So in a 3x2 grid, index 0
      # is the bottom left quadrat and index 5 is the top right corner.
      #
      # Method to determine bins is finding the percentile the point falls
      # on of the range, then multiplying by the regions and taking the
      # floor of that. This only works because each region is equal size.
      #
      # @returns [Integer] index of the quadrat it is in
      def point_quadrat(point)
        xmin = bbox[0][0]
        xmax = bbox[1][0] + 1e-5 # add padding for edge point
        ymin = bbox[0][1]
        ymax = bbox[1][1] + 1e-5 # add padding for edge point

        xdiff = point[0] - xmin
        ydiff = point[1] - ymin

        x_bin = (xdiff * x_regions / (xmax - xmin)).floor
        y_bin = (ydiff * y_regions / (ymax - ymin)).floor

        x_bin + (x_regions * y_bin)
      end
    end
  end
end
