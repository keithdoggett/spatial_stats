# frozen_string_literal: true

require 'test_helper'

class ContiguousWeightsTest < ActiveSupport::TestCase
  def setup
    # create a 3x3 unit square grid
    grid = Polygon.grid(0, 0, 1, 3)
    grid.each(&:save)
  end

  def test_queen_weights
    scope = Polygon.all
    weights = SpatialStats::Weights::Contiguous
              .queen_weights(scope, :geom)

    assert_equal(9, weights.keys.size)
    assert_equal(40, weights.full.sum)
  end

  def test_rook_weights
    scope = Polygon.all
    weights = SpatialStats::Weights::Contiguous
              .rook_weights(scope, :geom)

    assert_equal(9, weights.keys.size)
    assert_equal(24, weights.full.sum)
  end
end
