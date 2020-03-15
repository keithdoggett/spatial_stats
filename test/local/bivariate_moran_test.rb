# frozen_string_literal: true

require 'test_helper'

class LocalBivariateMoranTest < ActiveSupport::TestCase
  def setup
    polys = Polygon.grid(0, 0, 1, 3)

    @values = [0, 1, 0, 1, 0, 1, 0, 1, 0]
    @second_values = [1, 2, 2, 1, 2, 2, 1, 2, 2]
    polys.each_with_index do |poly, i|
      poly.value = @values[i]
      poly.second_value = @second_values[i]
      poly.save
    end

    @poly_scope = Polygon.all
    @weights = SpatialStats::Weights::Contiguous.rook_weights(@poly_scope, :geom)
  end

  def test_x
    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    x = moran.x
    expected = @values.standardize
    assert_equal(expected, x)
  end

  def test_y
    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    y = moran.y
    expected = @second_values.standardize
    assert_equal(expected, y)
  end

  def test_i
    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    i = moran.i
    expected_i = [0.281091, 0, -0.562183, -0.702728, -0.140546,
                  0.702728, 0.281091, 0, -0.562183]
    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end
end
