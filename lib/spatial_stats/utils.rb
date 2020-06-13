# frozen_string_literal: true

require 'spatial_stats/utils/kd_tree'
require 'spatial_stats/utils/lag'

module SpatialStats
  ##
  # The Utils module contains various utilities used in the gem.
  module Utils
    ##
    # Compute the false discovery rate (FDR) of a set of p-values given
    # an alpha value.
    #
    # If there is no FDR available in the dataset, the Bonferroni Bound is
    # returned instead.
    #
    # @param [Array] pvals from an mc test
    # @param [Float] alpha value for the fdr
    #
    # @returns [Float] either the FDR or Bonferroni Bound
    def self.fdr(pvals, alpha)
      n = pvals.size
      b_bound = alpha / n
      pvals.sort!

      p_val = b_bound
      (0..n - 1).each do |i|
        p_fdr = (i + 1) * b_bound
        break unless pvals[i] <= p_fdr

        p_val = p_fdr
      end
      p_val
    end
  end
end
