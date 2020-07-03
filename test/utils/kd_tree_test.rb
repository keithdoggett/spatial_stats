# frozen_string_literal: true

require 'test_helper'

class KDTreeTest < ActiveSupport::TestCase
  def naive_nn(point, points); end

  def test_initialize
    points = [[-1, -1], [1, -1], [1, 1], [-1, 1]]
    tree = SpatialStats::Utils::KDTree.new(points)

    assert_equal(points, tree.points)

    # test structure
    root = tree.root
    assert_equal(1, root.split)
    assert_equal(1, root.left.split)
    assert_equal(1, root.right.split)
    assert_equal(1, root.left.axis)
    assert_equal(1, root.right.axis)

    assert_equal([-1, -1], root.left.left.point)
    assert_equal([-1, 1], root.left.point)
    assert_equal([1, -1], root.point)
    assert_equal([1, 1], root.right.point)

    assert_equal(0, root.left.left.idx)
    assert_equal(3, root.left.idx)
    assert_equal(1, root.idx)
    assert_equal(2, root.right.idx)
  end

  def test_nearest_point
    points = [[-1, -1], [1, -1], [1, 1], [-1, 1], [0, 0]]
    tree = SpatialStats::Utils::KDTree.new(points)
    test_point = [-0.6, -0.6]

    result = tree.nearest_point(test_point)
    expected = { point: [-1, -1], idx: 0, dist: 0.565 }
    assert_equal(expected[:point], result[:node].point)
    assert_equal(expected[:idx], result[:node].idx)
    assert_in_delta(expected[:dist], result[:dist], 1e-3)
  end

  def test_knn
    points = [[-1, -1], [1, -1], [1, 1], [-1, 1], [0, 0]]
    tree = SpatialStats::Utils::KDTree.new(points)
    test_point = [-0.6, -0.6]

    result = tree.knn(test_point, 2)
    expected = [
      { point: [-1, -1], idx: 0, dist: 0.565 },
      { point: [0, 0], idx: 4, dist: 0.8485 }
    ]
    expected.each_with_index do |v, i|
      assert_equal(v[:point], result[i][:node].point)
      assert_equal(v[:idx], result[i][:node].idx)
      assert_in_delta(v[:dist], result[i][:dist], 1e-3)
    end
  end

  def test_point_radius_search
    # concentric squares centered at 0, one with l = 1 the other with l = 2
    points = [[-1, -1], [1, -1], [1, 1], [-1, 1],
              [-2, -2], [2, -2], [2, 2], [-2, 2]]
    tree = SpatialStats::Utils::KDTree.new(points)
    test_point = [0, 0]
    test_radius = 1.5 # slightly higher than sqrt(2)

    result = tree.point_radius_search(test_point, test_radius)
    expected = [
      { point: [1, -1], dist: Math.sqrt(2), idx: 1 },
      { point: [-1, 1], dist: Math.sqrt(2), idx: 3 },
      { point: [-1, -1], dist: Math.sqrt(2), idx: 0 },
      { point: [1, 1], dist: Math.sqrt(2), idx: 2 }
    ]
    expected.each_with_index do |v, i|
      assert_equal(v[:point], result[i][:node].point)
      assert_equal(v[:idx], result[i][:node].idx)
      assert_in_delta(v[:dist], result[i][:dist], 1e-3)
    end
  end
end
