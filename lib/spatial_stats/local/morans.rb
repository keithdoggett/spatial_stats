# frozen_string_literal: true

# https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/h-how-cluster-and-outlier-analysis-anselin-local-m.htm
module SpatialStats
  module Local
    class Morans
      def initialize(scope, field, weights)
        @scope = scope
        @field = field
        @weights = weights
      end
      attr_accessor :scope, :field, :weights

      def i
        # first compute Si**2 vector
        si2 = si2_calc
        wij = @weights.full
        vector = []
        z.each_with_index do |z_val, idx|
          sum_term = 0
          z.each_with_index do |zj_val, j|
            sum_term += wij[idx, j] * zj_val if idx != j
          end
          
          vector << (z_val / si2[idx]) * sum_term
        end
        vector
      end

      def variables
        @variables ||= SpatialStats::Queries::Variables.query_field(@scope, @field)
      end

      def zbar
        variables.sum / variables.size
      end

      def z
        variables.map { |val| val - zbar }
      end

      private

      def si2_calc
        n = @weights.keys.size
        si2 = []
        
        z.each_with_index do |_z_val, idx|
          # add all zs**2 where j != i
          numerator = 0
          z.each_with_index do |z_val, j|
            numerator += z_val**2 if j != idx
          end
          si2 << numerator / (n - 1)
        end
        si2
      end
    end
  end
end