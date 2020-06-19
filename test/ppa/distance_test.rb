# frozen_string_literal: true

require 'test_helper'

class PPADistanceTest < ActiveSupport::TestCase
  def setup
    @points = [[0, 0], [1, 2], [2, 3], [3, 4], [-1.5, -1.5], [2, 2]]
    @pp = SpatialStats::PPA::PointPattern.new(@points)
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
end
