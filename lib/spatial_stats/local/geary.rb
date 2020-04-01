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
        zs = Numo::DFloat.cast(z)
        zi = (z[idx] - zs)**2
        (w[idx, true] * zi).sum
      end

      def mc_i(wi, perms, idx)
        zi = (z[idx] - perms)**2
        (wi * zi).sum(1)
      end

      def x
        @x ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
                                               .standardize
      end
      alias z x

      private

      def w
        @w ||= weights.full.row_standardized
      end
    end
  end
end
