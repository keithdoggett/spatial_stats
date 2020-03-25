# frozen_string_literal: true

module SpatialStats
  module Local
    class Geary < Stat
      def initialize(scope, field, weights)
        super(scope, field, weights)
      end
      attr_writer :x

      def i
        z.each_with_index.map do |_zi, idx|
          i_i(idx)
        end
      end

      def i_i(idx)
        n = w.row_size
        sum = 0
        (0..n - 1).each do |j|
          sum += w[idx, j] * ((z[idx] - z[j])**2)
        end
        sum
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

      def mc(permutations = 99, seed = nil)
        super(permutations, seed)
      end

      private

      def w
        @w ||= weights.full.row_standardized
      end
    end
  end
end
