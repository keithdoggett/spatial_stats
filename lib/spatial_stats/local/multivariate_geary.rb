# frozen_string_literal: true

module SpatialStats
  module Local
    ##
    # MultivariateGeary works like univariate Geary, except that it takes
    # an array of data fields, rather than one data field. It measures the
    # extent to which the average distance in attribute space between
    # values and its neighbors compared to what they would be under spatial
    # randomness.
    #
    # Functionally, C is computed by averaging the C values for each attribute
    # at a certain location, under a univariate context.
    class MultivariateGeary < Stat
      ##
      # A new instance of Moran
      #
      # @param [ActiveRecord::Relation] scope
      # @param [Symbol, String] fields to query from scope
      # @param [WeightsMatrix] weights to define relationship between observations in scope
      #
      # @return [MultivariateGeary]
      def initialize(scope, fields, weights)
        @scope = scope
        @fields = fields
        @weights = weights.standardize
      end
      attr_accessor :scope, :fields, :weights

      ##
      # Computes the stat for MultivariateGeary.
      #
      # @see https://geodacenter.github.io/workbook/6b_local_adv/lab6b.html#concept-5
      #
      # @return [Array] of C values for each observation.
      def stat
        m = fields.size
        gearys = fields.map do |field|
          Geary.new(scope, field, weights).stat
        end
        gearys.transpose.map { |x| x.reduce(:+) / m }
      end
      alias c stat

      ##
      # Permutation test to determine a pseudo p-values of the +#stat+ method.
      # Shuffles all tuples, recomputes +#stat+ for each variation, then compares
      # to the computed one. The ratio of more extreme values to
      # permutations is returned for each observation.
      #
      # @see https://geodacenter.github.io/glossary.html#perm
      #
      # @param [Integer] permutations to run. Last digit should be 9 to produce round numbers.
      # @param [Integer] seed used in random number generator for shuffles.
      #
      # @return [Array] of p-values
      def mc(permutations = 99, seed = nil)
        # in this case, one tuple of vals is held constant, then
        # the rest are shuffled, so for crand we will pass in an arr
        # of indices, which will return a list of new orders for the fields.
        # They will then be shuffled corresponding to the new indices.
        rng = gen_rng(seed)
        rids = crand(permutations, rng)

        n_1 = weights.n - 1
        sparse = weights.sparse
        row_index = sparse.row_index
        ws = sparse.values
        wc = weights.wc
        stat_orig = stat

        ids = (0..n_1).to_a
        observations = Array.new(weights.n)
        (0..n_1).each do |idx|
          idsi = ids.dup
          idsi.delete_at(idx)
          idsi.shuffle!(random: rng)
          idsi = Numo::Int32.cast(idsi)
          sample = rids[idsi[rids[true, 0..wc[idx] - 1]]]

          # account for case where there are no neighbors
          row_range = row_index[idx]..(row_index[idx + 1] - 1)
          if row_range.size.zero?
            observations[idx] = permutations
            next
          end

          wi = Numo::DFloat.cast(ws[row_range])
          stat_i_new = mc_i(wi, sample, idx)
          stat_i_orig = stat_orig[idx]
          observations[idx] = mc_observation_calc(stat_i_orig, stat_i_new,
                                                  permutations)
        end

        observations.map do |ri|
          (ri + 1.0) / (permutations + 1.0)
        end
      end

      def groups
        raise NotImplementedError, 'groups not implemented'
      end

      private

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

      def mc_observation_calc(stat_i_orig, stat_i_new, _permutations)
        # Geary cannot be negative, so we have to use this technique from
        # GeoDa to determine p values. Note I slightly modified it to be inclusive
        # on both tails not just the lower tail.
        # https://github.com/GeoDaCenter/geoda/blob/master/Explore/LocalGearyCoordinator.cpp#L981        mean = stat_i_new.mean
        mean = stat_i_new.mean
        if stat_i_orig <= mean
          (stat_i_new <= stat_i_orig).count
        else
          (stat_i_new >= stat_i_orig).count
        end
      end

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
