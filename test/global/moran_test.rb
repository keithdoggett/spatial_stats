# frozen_string_literal: true

require 'test_helper'

class GlobalMoranTest < ActiveSupport::TestCase
  def setup
    polys = Polygon.grid(0, 0, 1, 3)

    # checkerboard will give < 0 I value
    @values = [0, 1, 0, 1, 0, 1, 0, 1, 0]
    polys.each_with_index do |poly, i|
      poly.value = @values[i]
      poly.save
    end

    @poly_scope = Polygon.all
    @weights = SpatialStats::Weights::Contiguous.rook(@poly_scope, :geom)
  end

  def test_x
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    x = moran.x
    assert_equal(@values, x)
  end

  def test_zbar
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    expected_zbar = 4.0 / 9
    zbar = moran.zbar
    assert_equal(expected_zbar, zbar)
  end

  def test_z
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    z = moran.z
    expected_z = [-4.0 / 9, 5.0 / 9, -4.0 / 9, 5.0 / 9,
                  -4.0 / 9, 5.0 / 9, -4.0 / 9, 5.0 / 9, -4.0 / 9]
    assert_equal(expected_z, z)
  end

  def test_i
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    i = moran.i
    expected_i = -1
    assert_equal(expected_i, i)
  end

  def test_i_clustered
    # replace bottom 2 rows values with 1, top row with 0
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    i = moran.i
    assert i.positive?
  end

  def test_expectation
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    expectation = moran.expectation
    expected = -1.0 / 8
    assert_equal(expected, expectation)
  end

  def test_variance
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    var = moran.variance
    expected = 0.0671875
    assert_in_delta(expected, var, 0.005)
  end

  def test_z_score
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    var = moran.z_score
    expected = -3.375
    assert_in_delta(expected, var, 0.05)
  end

  def test_mc
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_val = moran.mc(999, seed)
    expected = 0.001
    assert_in_delta(expected, p_val, 0.005)
  end
end
