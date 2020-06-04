# frozen_string_literal: true

require 'test_helper'

class CentrographyTest < ActiveSupport::TestCase
  def setup
    @points = [[0, 0], [0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5]]
    @points2 = [[0, 0], [0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5], [2, 2]]
    @pp = SpatialStats::PPA::PointPattern.new(@points)
    @pp2 = SpatialStats::PPA::PointPattern.new(@points2)
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

  def test_standard_distance
    std = @pp.standard_distance
    expected = 2.4065881
    assert_in_delta(expected, std, 1e-5)
  end

  def test_median_even
    med = @pp.median
    expected = [0.5, 1.0]
    assert_equal(expected, med)
  end

  def test_median_odd
    med = @pp2.median
    expected = [1.0, 2.0]
    assert_equal(expected, med)
  end

  def test_center_median
    center = @pp2.center_median
    expected = [1.114538, 1.851077]
    center.each_with_index do |v, i|
      assert_in_delta(expected[i], v, 1e-2)
    end
  end

  def test_sd_ellipse
    sde = @pp.sd_ellipse
    expected = [0.27544, 1.11875, 0.65322]
    sde.each_with_index do |v, i|
      assert_in_delta(expected[i], v, 1e-5)
    end
  end
end
