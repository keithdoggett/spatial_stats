# frozen_string_literal: true

module SpatialStats
  module Local
    class MultivariateGeary < Stat
      def initialize(scope, fields, weights)
        @scope = scope
        @fields = fields
        @weights = weights
      end
      attr_accessor :scope, :fields, :weights

      def stat
        m = fields.size
        gearys = fields.map do |field|
          Geary.new(scope, field, weights).stat
        end
        gearys.transpose.map { |x| x.reduce(:+) / m }
      end
      alias c stat

      def mc_i(wi, perms, idx)
        m = fields.size
        permutations = perms.shape[0]

        cs = Numo::DFloat.zeros(m, permutations)
        (0..m - 1).each do |mi|
          z = field_data[mi]
          zs = matrix_field_data[mi, true][perms]
          c = (z[idx] - zs)**2

          cs[mi, true] = (wi * c).sum(1)
        end
        cs.mean(0)
      end

      def mc(permutations = 99, seed = nil)
        # in this case, one tuple of vals is held constant, then
        # the rest are shuffled, so for crand we will pass in an arr
        # of indices, which will return a list of new orders for the fields.
        # They will then be shuffled corresponding to the new indices.
        rng = gen_rng(seed)
        n = w.shape[0]
        indices = (0..(n - 1)).to_a
        shuffles = crand(indices, permutations, rng)

        stat_orig = stat
        rs = [0] * n

        ws = neighbor_weights

        idx = 0
        while idx < n
          stat_i_orig = stat_orig[idx]
          wi = Numo::DFloat.cast(ws[idx])

          # for each field, compute the C value at that index.
          stat_i_new = mc_i(wi, shuffles[idx], idx)

          rs[idx] = if stat_i_orig.positive?
                      (stat_i_new >= stat_i_orig).count
                    else
                      (stat_i_new <= stat_i_orig).count
                    end

          idx += 1
        end

        rs.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
      end

      private

      def field_data
        @field_data ||= fields.map do |field|
          SpatialStats::Queries::Variables.query_field(@scope, field)
                                          .standardize
        end
      end

      def matrix_field_data
        @matrix_field_data ||= Numo::DFloat.cast(field_data)
      end
    end
  end
end
