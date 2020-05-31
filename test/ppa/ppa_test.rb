# frozen_string_literal: true

require 'test_helper'

class PPATest < ActiveSupport::TestCase
  def setup
    @points = [[0, 0], [0, 1], [1, 2], [3, 4], [5, 6], [-1.5, -1.5]]
  end

  def test_point_pattern_initialize
    pp = SpatialStats::PPA::PointPattern.new(@points)
    assert_equal(@points, pp.points)
    assert_equal(6, pp.n)
  end
end
