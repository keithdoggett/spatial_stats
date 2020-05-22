# frozen_string_literal: true

require 'test_helper'

class GlobalBivariateMoranTest < ActiveSupport::TestCase
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
    @weights = SpatialStats::Weights::Contiguous.rook(@poly_scope, :geom)
  end

  def test_x
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    x = moran.x
    expected = @values.standardize
    assert_equal(expected, x)
  end

  def test_y
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    y = moran.y
    expected = @second_values.standardize
    assert_equal(expected, y)
  end

  def test_x=
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    moran.x = @values
    expected = @values.standardize
    assert_equal(expected, moran.x)
  end

  def test_y=
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    moran.y = @second_values
    expected = @second_values.standardize
    assert_equal(expected, moran.y)
  end

  def test_stat
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    i = moran.stat
    expected_i = -0.088
    assert_in_delta(expected_i, i, 1e-3)
  end

  def test_expectation
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    expectation = moran.expectation
    expected = -1.0 / 8
    assert_equal(expected, expectation)
  end

  def test_variance
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    var = moran.variance
    expected = 0.07316
    assert_in_delta(expected, var, 0.0005)
  end

  def test_z_score
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    var = moran.z_score
    expected = 0.1373
    assert_in_delta(expected, var, 0.0005)
  end

  def test_mc
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)

    seed = 123_456_789
    p_val = moran.mc(999, seed)
    expected = 0.608
    assert_in_delta(expected, p_val, 0.005)
  end
end
