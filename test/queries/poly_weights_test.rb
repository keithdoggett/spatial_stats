# frozen_string_literal: true

class PolygonQueryWeightsTest < ActiveSupport::TestCase
  def setup
    # create 3x3 grid of polygons
    polygons = Polygon.grid(0, 0, 1, 3)
    polygons.each(&:save)
  end

  def test_queen_contiguity_neighbors
    scope = Polygon.all
    neighbors = SpatialStats::Queries::Weights
                .queen_contiguity_neighbors(scope, :geom)

    # in a 3x3 grid, queen contiguities are as follows
    # corners - 3 (2 adjacent and center)
    # edges - 5 (center, 2 corners, 2 other edges)
    # center - 8 (4 corners, 4 edges)

    # there are 4 corners, 4 edges, and 1 center, so
    # the total neighbor count is 12 + 20 + 8 = 40
    assert_equal(40, neighbors.size)

    valid_sizes = [3, 5, 8]
    groups = neighbors.group_by(&:i_id)
    groups.each do |_cell, neighbors|
      assert_includes(valid_sizes, neighbors.size)
    end
  end

  def test_rook_contiguity_neighbors
    scope = Polygon.all
    neighbors = SpatialStats::Queries::Weights
                .rook_contiguity_neighbors(scope, :geom)

    # in a 3x3 grid, rook contiguities are as follows
    # corners - 2 (2 adjacent)
    # edges - 3 (center, 2 corners)
    # center - 4 (4 edges)

    # there are 4 corners, 4 edges, and 1 center, so
    # the total neighbor count is 8 + 12 + 4 = 24
    assert_equal(24, neighbors.size)

    valid_sizes = [2, 3, 4]
    groups = neighbors.group_by(&:i_id)
    groups.each do |_cell, neighbors|
      assert_includes(valid_sizes, neighbors.size)
    end
  end
end
