# frozen_string_literal: true

require 'test_helper'

class CentrographyTest < ActiveSupport::TestCase
  def setup
    @points = [[0, 0], [0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5]]
    @pp = SpatialStats::PPA::PointPattern.new(@points)
  end

  def test_mean_center
    mc = @pp.mean_center
    expected = [0.75, 1.25]
    assert_equal(expected, mc)
  end

  def test_weighted_mean_center
    weights = [0, 1, 2, 3, 4, 5]
    wmc = @pp.weighted_mean_center(weights)
    expected = [5.0 / 6, 43.0 / 30]
    assert_equal(expected, wmc)
  end

  def test_weighted_mean_center_invalid_len
    short_weights = [1, 2]
    assert_raises(ArgumentError) { @pp.weighted_mean_center(short_weights) }
  end

  def test_median_even
    med = @pp.median
    expected = [0.5, 1.0]
    assert_equal(expected, med)
  end

  def test_median_odd
    points = [[0, 0], [0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5], [2, 2]]
    pp = SpatialStats::PPA::PointPattern.new(points)
    med = pp.median
    expected = [1.0, 2.0]
    assert_equal(expected, med)
  end
end
