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
    @weights = SpatialStats::Weights::Contiguous.rook_weights(@poly_scope, :geom)
  end

  def test_x_vars
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    vars = moran.x_vars
    expected = @values.standardize
    assert_equal(expected, vars)
  end

  def test_y_vars
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    vars = moran.y_vars
    expected = @second_values.standardize
    assert_equal(expected, vars)
  end

  def test_i
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    i = moran.i
    expected_i = -0.0878410461157883
    assert_in_delta(expected_i, i, 1e-4)
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
    expected = 0.0671875
    assert_in_delta(expected, var, 0.0005)
  end

  def test_z_score
    moran = SpatialStats::Global::BivariateMoran
            .new(@poly_scope, :value, :second_value, @weights)
    var = moran.z_score
    expected = 0.14335711
    assert_in_delta(expected, var, 0.0005)
  end
end
