# frozen_string_literal: true

require 'test_helper'

class UtilsTest < ActiveSupport::TestCase
  def setup
    @pvals = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9,
              0.01, 0.02, 0.03, 0.04, 0.05, 0.06]
  end

  def test_fdr_has_cutoff
    # in this case, pvals will be less than their fdr p, so the fdr can be
    # computed
    alpha = 0.2
    expected = 0.08
    fdr = SpatialStats::Utils.fdr(@pvals, alpha)
    assert_equal(expected, fdr)
  end

  def test_fdr_no_cutoff
    # even the smallest p is not less than the smallest fdr, so
    # return bonferroni bound
    alpha = 0.0001
    expected = alpha / 15
    fdr = SpatialStats::Utils.fdr(@pvals, alpha)
    assert_equal(expected, fdr)
  end
end
