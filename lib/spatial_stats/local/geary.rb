# frozen_string_literal: true

module SpatialStats
  module Local
    class Geary < Stat
      def initialize(scope, field, weights)
        super(scope, field, weights)
      end

      def i
        w = weights.full.row_standardized
        n = w.row_size
        zs = x
        zs.each_with_index.map do |zi, idx|
          sum = 0
          (0..n - 1).each do |j|
            sum += w[idx, j] * ((zi - zs[j])**2)
          end
          sum
        end
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x
    end
  end
end
