# frozen_string_literal: true

require 'test_helper'
require 'rubystats'

class PPADistanceTest < ActiveSupport::TestCase
  def setup
    @points = [[0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5], [2, 2]]
    @pp = SpatialStats::PPA::PointPattern.new(@points)

    seed = 123_456
    Kernel.srand(seed)
  end

  def test_knn
    knn = @pp.knn
    expected_idx = [4, 5, 5, 2, 0, 2]

    knn_idx = knn.flatten.map { |v| v[:node].idx }
    assert_equal(expected_idx, knn_idx)
  end

  def test_nn_dist
    nn_dist = @pp.nn_dist
    expected = [2.121, 1.0, 1.0, 1.414, 2.121, 1.0]

    expected.each_with_index do |v, i|
      assert_in_delta(v, nn_dist[i], 1e-2)
    end
  end

  def test_mean_nn_dist
    mean_dist = @pp.mean_nn_dist
    expected = 1.4426
    assert_in_delta(expected, mean_dist, 1e-2)
  end

  def test_stddev_nn_dist
    std_dev = @pp.stddev_nn_dist
    expected = 0.54935
    assert_in_delta(expected, std_dev, 1e-2)
  end

  def test_min_nn_dist
    min_dist = @pp.min_nn_dist
    expected = 1.0
    assert_equal(expected, min_dist)
  end

  def test_max_nn_dist
    max_dist = @pp.max_nn_dist
    expected = 2.121
    assert_in_delta(expected, max_dist, 1e-2)
  end

  def test_expected_nn_dist
    expected_dist = @pp.expected_nn_dist
    area = 24.75 # from bbox of pp
    expected = 1 / (2 * Math.sqrt(6 / area))
    assert_equal(expected, expected_dist)
  end

  def test_expected_nn_dist_custom_bounds
    bounds = [[-2, -2], [6, 6]]
    expected_dist = @pp.expected_nn_dist(bounds)
    area = 64.0
    expected = 1 / (2 * Math.sqrt(6 / area))
    assert_equal(expected, expected_dist)
  end

  def test_p_value
    # random gen points
    unif_dist = Rubystats::UniformDistribution.new(0, 1000)
    pts = 1000.times.map { [unif_dist.rng, unif_dist.rng] }
    pp = SpatialStats::PPA::PointPattern.new(pts)

    p_value = pp.p_value([[0, 0], [1000, 1000]])
    assert_in_delta(0.58, p_value[:clustered], 1e-2)
    assert_in_delta(0.42, p_value[:dispersed], 1e-2)
  end

  def test_p_value_clustered
    unif_dist = Rubystats::UniformDistribution.new(0, 100)
    pts = 100.times.map { [unif_dist.rng, unif_dist.rng] }
    pp = SpatialStats::PPA::PointPattern.new(pts)

    p_value = pp.p_value([[0, 0], [1000, 1000]])
    assert_in_delta(1e-5, p_value[:clustered], 1e-2)
    assert_in_delta(1.0, p_value[:dispersed], 1e-2)
  end

  def test_mc
    unif_dist = Rubystats::UniformDistribution.new(0, 100)
    pts = 100.times.map { [unif_dist.rng, unif_dist.rng] }
    pp = SpatialStats::PPA::PointPattern.new(pts)

    p_value = pp.mc([[0, 0], [1000, 1000]], 99)
    assert_in_delta(0.01, p_value[:clustered], 1e-2)
    assert_in_delta(1.0, p_value[:dispersed], 1e-2)
  end
end
