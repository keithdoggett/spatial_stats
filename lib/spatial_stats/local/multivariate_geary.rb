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
        indices = (0..(n - 1)).to_a
        shuffles = crand(indices, permutations, rng)

        i_orig = i
        rs = [0] * i_orig.size
        shuffles.each_with_index do |perms, idx|
          ii_orig = i_orig[idx]
          perms.each do |perm|
            # essentially reimplement i here, but only use i_i
            m = fields.size
            gearys = fields.each_with_index.map do |field, field_idx|
              geary = Geary.new(scope, field, weights)
              geary.x = field_data[field_idx].values_at(*perm)
              geary.i_i(idx)
            end
            ii_new = gearys.sum { |x| x / m }

            if ii_orig.positive?
              rs[idx] += 1 if ii_new >= ii_orig
            else
              rs[idx] += 1 if ii_new <= ii_orig
            end
          end
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
