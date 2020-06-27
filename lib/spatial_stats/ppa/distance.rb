# frozen_string_literal: true

require 'rubystats'

module SpatialStats
  module PPA
    class PointPattern
      ##
      # Returns the index of the K-Nearest Neighbors
      # for every point in the PointPattern
      #
      # @param [Integer] k neighbors
      #
      # @returns [Array] [{idx: Integer, dist: Float}] array of arrays of size k
      def knn(k = 1)
        points.map do |pt|
          # Ignore the first entry because that will be
          # the point passed in
          kd_tree.knn(pt, k + 1).slice(1..k + 1)
        end
      end

      ##
      # Compute the distance of the nearest neighbor to each point
      #
      # @returns [Array] of floats
      def nn_dist
        knn(1).flatten.map { |v| v[:dist] }
      end

      ##
      # Compute the mean nearest neighbor distance to each point
      #
      # @returns [Float]
      def mean_nn_dist
        nn_dist.mean
      end

      ##
      # Compute the standard deviation of the nearest neighbors
      # distance
      #
      # @returns [Float]
      def stddev_nn_dist
        Math.sqrt(nn_dist.sample_variance)
      end

      ##
      # Compute the min nearest neighbor distance to each point
      #
      # @returns [Float]
      def min_nn_dist
        nn_dist.min
      end

      ##
      # Compute the max nearest neighbor distance to each point
      #
      # @returns [Float]
      def max_nn_dist
        nn_dist.max
      end

      ##
      # Return the expected nearest neighbor distance based on area
      # and instensity
      #
      # @param [Array] bounds of area if different from bbox
      #
      # @returns [Float]
      def expected_nn_dist(bounds = nil)
        bounds = bbox if bounds.nil?
        area = area_from_bounds(bounds)
        lam = n / area.to_f
        1 / (2 * Math.sqrt(lam))
      end

      ##
      # Analytical calculation of the p_value given the target boundary.
      #
      # Gives 2 tailed p-value by providing p values for both clustering
      # and dispersion
      #
      # Uses a normal distribution to approximate the CSR distribution
      # with mean expected_nn_dist and variance = (4-pi)/(4*n*lambda*pi)
      #
      # @note Using the bbox may provide weird results. It is recommended
      # to use the bounding box of the target area instead.
      #
      # @param [Array] bounds of area if different from bbox
      #
      # @returns [Hash] {clustered: Float, dispersed: Float}
      def p_value(bounds = nil)
        bounds = bbox if bounds.nil?
        area = area_from_bounds(bounds)
        lam = n / area.to_f
        exp_mean = expected_nn_dist(bounds)
        variance = (4.0 - Math::PI) / (n * lam * 4.0 * Math::PI)

        z = (mean_nn_dist - exp_mean) / Math.sqrt(variance)
        dist = Rubystats::NormalDistribution.new(0, 1)

        # p x < mean
        p_val = dist.cdf(z)
        { clustered: p_val, dispersed: 1 - p_val }
      end

      ##
      # Permutation test for CSR. Simulates point patterns using a
      # CSR point process to create a distribution of mean_nn_dists.
      # Compares mean_nn_dist to each simulated dist and returns p values
      # at each tail, one for clustering and one for dispersion.
      #
      # @param [Array] bounds of area if different from bbox
      # @param [Integer] permutations, number of permutations to simulate
      # @param [Number] seed, random seed
      #
      # @returns [Hash] {clustered: Float, dispersed: Float}
      def mc(bounds = nil, permutations = 99, seed = nil)
        Kernel.srand(seed) unless seed.nil?
        bounds = bbox if bounds.nil?
        mean_dist = mean_nn_dist

        # keep track of observations
        more_clustered = 0
        more_dispersed = 0

        permutations.times do
          csr_pts = PointProcess.generate_from_n(bounds, n)
          sim_pp = self.class.new(csr_pts)
          sim_mnn = sim_pp.mean_nn_dist

          if sim_mnn < mean_dist
            more_clustered += 1
          else
            more_dispersed += 1
          end
        end

        { clustered: (more_clustered + 1.0) / (permutations + 1.0),
          dispersed: (more_dispersed + 1.0) / (permutations + 1.0) }
      end

      private

      def area_from_bounds(bounds)
        (bounds[1][0] - bounds[0][0]) * (bounds[1][1] - bounds[0][1])
      end
    end
  end
end
