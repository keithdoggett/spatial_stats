# frozen_string_literal: true

require 'test_helper'

class KDTreeTest < ActiveSupport::TestCase
  # to get KDTree and Node more easily
  include SpatialStats::Utils

  def setup
    @points = [[-1, -1], [1, -1], [1, 1], [-1, 1]]
  end

  def test_initialize
    tree = KDTree.new(@points)

    assert_equal(@points, tree.points)

    # test structure
    head = tree.head
    assert_equal(1, head.split)
    assert_equal(1, head.left.split)
    assert_nil(head.right.split)
    assert_equal(1, head.left.axis)
    assert_nil(head.right.axis)

    assert_equal([-1, -1], head.left.left.point)
    assert_equal([-1, 1], head.left.point)
    assert_equal([1, -1], head.point)
    assert_equal([1, 1], head.right.point)

    assert_equal(0, head.left.left.idx)
    assert_equal(3, head.left.idx)
    assert_equal(1, head.idx)
    assert_equal(2, head.right.idx)
  end
end
