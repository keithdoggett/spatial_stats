# frozen_string_literal: true

module SpatialStats
  module PPA
    class DistanceStatistic
      def initialize(pp, intervals = 10)
        @pp = pp
        @intervals = intervals
      end
      attr_accessor :pp, :intervals

      ##
      # Calculate the bins based off of the number of intervals
      #
      # @returns [Array] of bin edges
      def bins
        @bins ||= begin
          # compute w, use quarter length of minimum side of bbox as max dist
          bbox = pp.bbox
          q_len = 0.25 * [bbox[1][0] - bbox[0][0], bbox[1][1] - bbox[0][1]].min
          w = q_len / intervals

          (0..intervals + 1).map do |i|
            w * i
          end
        end
      end

      def expectation
        raise NotImplementedError
      end

      def stat
        raise NotImplementedError
      end
    end

    class KStatistic < DistanceStatistic
      def expectation
        @expectation ||= begin
          bins.map do |dist|
            dist**2 * Math::PI
          end
        end
      end

      ##
      # Compute the K value of the point pattern.
      #
      # At each bin, the k value is number of pairs within d of each other
      # divided by lambda * n
      #
      # @returns [Array]
      def stat
        denom = pp.lambda * pp.n
        bins.map do |dist|
          pp.pairs_in_radius(dist).size / denom
        end
      end
      alias k stat
    end

    class LStatistic < DistanceStatistic
      def expectation
        @expectation ||= Array.new(bins.size, 0)
      end

      ##
      # Compute the L value of the point pattern.
      #
      # At each bin, the l value is the sqrt(K(d)/PI) - d
      #
      # @returns [Array]
      def stat
        denom = pp.lambda * pp.n
        bins.map do |dist|
          k = pp.pairs_in_radius(dist).size / denom
          Math.sqrt(k / Math::PI) - dist
        end
      end
    end
  end
end
