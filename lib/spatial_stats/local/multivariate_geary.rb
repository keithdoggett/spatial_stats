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

      def i
        m = fields.size
        gearys = fields.map do |field|
          Geary.new(scope, field, weights).i
        end
        gearys.transpose.map { |x| x.reduce(:+) / m }
      end

      def mc(permutations = 99, seed = nil)
        # in this case, one tuple of vals is held constant, then
        # the rest are shuffled, so for crand we will pass in an arr
        # of indices, which will return a list of new orders for the fields.
        # They will then be shuffled corresponding to the new indices.
        rng = gen_rng(seed)
        n = w.shape[0]
        m = field_data.size
        indices = (0..(n - 1)).to_a
        shuffles = crand(indices, permutations, rng)

        ws = [[]] * n
        (0..weights.n - 1).each do |idx|
          neighbors = []
          w[idx, true].each do |wij|
            neighbors << wij if wij != 0
          end
          ws[idx] = neighbors
        end

        i_orig = i
        rs = [0] * i_orig.size

        idx = 0
        f_data = Numo::DFloat.cast(field_data)

        while idx < n
          ii_orig = i_orig[idx]
          wi = Numo::DFloat.cast(ws[idx])

          # for each field, compute the C value at that index.
          cs = Numo::DFloat.zeros(m, permutations)
          (0..m - 1).each do |mi|
            field = field_data[mi]
            zs = f_data[mi, true][shuffles[idx]]
            c = (field[idx] - zs)**2

            cs[mi, true] = (wi * c).sum(1)
          end
          ii_new = cs.mean(0)

          rs[idx] = if ii_orig.positive?
                      (ii_new >= ii_orig).count
                    else
                      (ii_new <= ii_orig).count
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
    end
  end
end
