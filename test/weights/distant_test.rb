# frozen_string_literal: true

require 'test_helper'

class DistantWeightsTest < ActiveSupport::TestCase
  def setup
    # make a 3x3 grid of polygons, then take the centroid of
    # each cell and save that as the point.
    grid = Polygon.grid(0, 0, 1, 3)
    grid.each do |cell|
      pt = Point.new(position: cell.centroid)
      pt.save
    end
  end

  def test_distance_band
    scope = Point.all
    bandwidth = 1

    weights = SpatialStats::Weights::Distant
              .distance_band(scope, :position, bandwidth)

    # same as rook contiguity, so 24 matches
    assert_equal(9, weights.n)
    assert_equal(24, weights.dense.sum.round)
  end

  def test_knn
    scope = Point.all
    neighbors = 4

    weights = SpatialStats::Weights::Distant
              .knn(scope, :position, neighbors)

    assert_equal(9, weights.n)
    assert_equal(36, weights.dense.sum.round)
  end

  def test_idw_band
    scope = Point.all
    bandwidth = Math.sqrt(2)
    alpha = 2

    weights = SpatialStats::Weights::Distant
              .idw_band(scope, :position, bandwidth, alpha)

    assert_equal(9, weights.n)
    assert_equal(32.0, weights.dense.sum.round)
  end

  def test_idw_knn
    scope = Point.all
    neighbors = 4
    alpha = 2

    weights = SpatialStats::Weights::Distant
              .idw_knn(scope, :position, neighbors, alpha)

    assert_equal(9, weights.n)
    assert_equal(29.0, weights.dense.sum.round)
  end
end
