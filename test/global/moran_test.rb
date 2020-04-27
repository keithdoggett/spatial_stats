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
    expected = @values.standardize
    assert_equal(expected, x)
  end

  def test_stat
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    i = moran.stat
    expected = -1.0
    assert_in_delta(expected, i, 0.005)
  end

  def test_stat_clustered
    # replace bottom 2 rows values with 1, top row with 0
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    i = moran.stat
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
    assert_in_delta(expected, var, 0.05)
  end

  def test_z_score
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    var = moran.z_score
    expected = -3.375
    assert_in_delta(expected, var, 0.5)
  end

  def test_mc
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_val = moran.mc(999, seed)
    expected = 0.01

    assert_in_delta(expected, p_val, 0.005)
  end

  def test_summary
    moran = SpatialStats::Global::Moran.new(@poly_scope, :value, @weights)
    seed = 123_456
    summary = moran.summary(999, seed)
    expected = { stat: -1.0, p: 0.01 }

    assert_in_delta(expected[:stat], summary[:stat], 1e-5)
    assert_in_delta(expected[:p], summary[:p], 1e-5)
  end
end
