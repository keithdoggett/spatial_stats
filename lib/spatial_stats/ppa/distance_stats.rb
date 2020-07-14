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
      #
      # @returns [Array] of bin edges
      def bins
        @bins ||= begin
          # compute w, use ripley's rule of thumb to estimate distance
          bbox = pp.bbox
          rot = 0.25 * [bbox[1][0] - bbox[0][0], bbox[1][1] - bbox[0][1]].min
          w = rot / intervals

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
    end

    class LStatistic < DistanceStatistic
      def expectation
        @expectation ||= Array.new(bins.size, 0)
      end
    end
  end
end
