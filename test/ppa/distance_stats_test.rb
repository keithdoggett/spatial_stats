# frozen_string_literal: true

require 'test_helper'

class DistanceStatisticTest < ActiveSupport::TestCase
  def setup
    @points = [[0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5], [2, 2]]
    @pp = SpatialStats::PPA::PointPattern.new(@points)

    seed = 123_456
    Kernel.srand(seed)
  end

  def test_k_initialize
    k_stat = SpatialStats::PPA::KStatistic.new(@pp)
    expected_bins = [0.0, 0.1125, 0.225, 0.3375, 0.45, 0.5625, 0.675, 0.7875, 0.9, 1.0125, 1.125, 1.2375]
    assert_equal(10, k_stat.intervals)
    assert_equal(expected_bins, k_stat.bins)
  end

  def test_k_initialize_intervals
    k_stat = SpatialStats::PPA::KStatistic.new(@pp, 5)
    expected_bins = [0.0, 0.225, 0.45, 0.675, 0.9, 1.125, 1.35]
    assert_equal(5, k_stat.intervals)
    assert_equal(expected_bins, k_stat.bins)
  end

  def test_k_expectation
    k_stat = SpatialStats::PPA::KStatistic.new(@pp)
    expected = [0.0, 0.03976078, 0.15904313, 0.35784704, 0.63617251,
                0.99401955, 1.43138815, 1.94827832, 2.54469005, 3.22062334,
                3.9760782, 4.81105462]

    k_stat.expectation.each_with_index do |val, i|
      assert_in_delta(expected[i], val, 1e-4)
    end
  end

  def test_k_stat
    k_stat = SpatialStats::PPA::KStatistic.new(@pp)
    expected = [0, 0, 0, 0, 0, 0, 0, 0, 0, 2.75, 2.75, 2.75]
    assert_equal(expected, k_stat.stat)
  end

  def test_l_initialize
    l_stat = SpatialStats::PPA::LStatistic.new(@pp)
    expected_bins = [0.0, 0.1125, 0.225, 0.3375, 0.45, 0.5625, 0.675, 0.7875, 0.9, 1.0125, 1.125, 1.2375]
    assert_equal(10, l_stat.intervals)
    assert_equal(expected_bins, l_stat.bins)
  end

  def test_l_initialize_intervals
    l_stat = SpatialStats::PPA::LStatistic.new(@pp, 5)
    expected_bins = [0.0, 0.225, 0.45, 0.675, 0.9, 1.125, 1.35]
    assert_equal(5, l_stat.intervals)
    assert_equal(expected_bins, l_stat.bins)
  end

  def test_l_expectation
    l_stat = SpatialStats::PPA::LStatistic.new(@pp)
    expected = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    assert_equal(expected, l_stat.expectation)
  end

  def test_l_stat
    l_stat = SpatialStats::PPA::LStatistic.new(@pp)
    expected = [0.0, -0.1125, -0.225, -0.3375, -0.45, -0.5625, -0.675, -0.7875, -0.9,
                -0.07689742037261116, -0.1893974203726112, -0.30189742037261125]
    l_stat.stat.each_with_index do |l, i|
      assert_in_delta(expected[i], l, 1e-5)
    end
  end
end
