# frozen_string_literal: true

require 'test_helper'

class PointQueryWeightsTest < ActiveSupport::TestCase
  def setup
    # make a 3x3 grid of polygons, then take the centroid of
    # each cell and save that as the point.
    grid = Polygon.grid(0, 0, 1, 3)
    grid.each do |cell|
      pt = Point.new(position: cell.centroid)
      pt.save
    end
  end

  def test_distance_band_neighbors
    scope = Point.all
    distance = 1
    neighbors = SpatialStats::Queries::Weights
                .distance_band_neighbors(scope, :position, distance)

    # since all points are 1 unit apart, this is analagous to rook
    # contiguity weights
    assert_equal(24, neighbors.size)

    valid_sizes = [2, 3, 4]
    groups = neighbors.group_by(&:i_id)
    groups.each do |_cell, neighbors|
      assert_includes(valid_sizes, neighbors.size)
    end
  end

  def test_knn
    scope = Point.all
    neighbors = SpatialStats::Queries::Weights
                .knn(scope, :position, 4)

    # corners will match the 2 nearest edges, the center
    # and a random corner with the same x or y value
    # edges will match with the center, 2 adjacent corners
    # and a random edge (not the one opposite from it)
    # center will match with all 4 edges.
    # 9 * 4 = 36 total connections
    assert_equal(36, neighbors.size)

    groups = neighbors.group_by(&:i_id)
    groups.each do |cell, neighbors|
      target = Point.find(cell)
      neighbors.each do |neighbor|
        p2 = Point.find(neighbor.j_id).position
        p1 = target.position
        assert p2.distance(p1) <= 2.0
      end
    end
  end

  def test_idw_band
    scope = Point.all
    neighbors = SpatialStats::Queries::Weights
                .idw_band(scope, :position, 3, 1)

    # in this configuration, they will all be neighbors
    # but we still need to test the weights are what we expect
    assert_equal(72, neighbors.size)

    # From perspective of a corner,
    # 1 is to nearest edges
    # 1/sqrt(2) is to center
    # 1/2 is to nearest corner
    # 1/sqrt(5) is to opposite edges
    # 1/2sqrt(2) is to opposite corner
    # round to the third decimal because the Cartesian factory
    # returns floats that are slightly off
    valid_weights = [1, 1 / Math.sqrt(2), 1.0 / 2,
                     1 / Math.sqrt(5), 1 / (2 * Math.sqrt(2))]
                     .map {|v| v.round(3)}
    neighbors.each do |neighbor|
      assert_includes(valid_weights, neighbor[:weight].round(3))
    end
  end

  def test_idw_knn
    scope = Point.all
    neighbors = SpatialStats::Queries::Weights
                .idw_knn(scope, :position, 8, 2)

    # in this configuration, they will all be neighbors
    # but we still need to test the weights are what we expect
    assert_equal(72, neighbors.size)

    # From perspective of a corner distances are,
    # 1 is to nearest edges
    # 1/sqrt(2) is to center
    # 1/2 is to nearest corner
    # 1/sqrt(5) is to opposite edges
    # 1/2sqrt(2) is to opposite corner
    # alpha is 2, so these need to be squared
    valid_weights = [1, 1.0 / 2, 1.0 / 4, 1.0 / 5, 1.0 / 8]
    neighbors.each do |neighbor|
      # need to round weight because of floating point error
      assert_includes(valid_weights, neighbor[:weight].round(3))
    end
  end
end
