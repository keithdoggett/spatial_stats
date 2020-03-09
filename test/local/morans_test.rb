# frozen_string_literal: true

require 'test_helper'

class LocalMoransTest < ActiveSupport::TestCase
  def setup
    polys = Polygon.grid(0, 0, 1, 3)

    # checkerboard will give < 0 I value
    @values = [0, 1, 0, 1, 0, 1, 0, 1, 0]
    polys.each_with_index do |poly, i|
      poly.value = @values[i]
      poly.save
    end

    @poly_scope = Polygon.all
    @weights = SpatialStats::Weights::Contiguous.rook_weights(@poly_scope, :geom)
  end

  def test_variables
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    vars = moran.variables
    expected = @values.standardize
    assert_equal(expected, vars)
  end

  def test_zbar
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    expected_zbar = 0
    zbar = moran.zbar
    assert_in_delta(expected_zbar, zbar, 0.0005)
  end

  def test_z
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    z = moran.z
    expected_z = [-0.8432740427115678, 1.0540925533894598, -0.8432740427115678,
                  1.0540925533894598, -0.8432740427115678,
                  1.0540925533894598, -0.8432740427115678,
                  1.0540925533894598, -0.8432740427115678]
    assert_equal(expected_z, z)
  end

  def test_i
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    i = moran.i
    i.each do |i_i|
      assert i_i.negative?
    end
  end

  def test_i_clustered
    # replace bottom 2 rows values with 1, top row with 0
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)

    # these should all be slightly positive, or zero for the corners
    # this is the same output as the test from GeoDa
    i = moran.i
    expected_i = [0.4444444444444444, 0.4444444444444444, 0.4444444444444444,
                  0.0, 0.11111111111111112, 0.0, 0.4444444444444444,
                  0.8888888888888888, 0.4444444444444444]

    assert_equal(i, expected_i)
  end

  # def test_expectation
  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   expectation = moran.expectation
  #   expected = -1.0 / 8
  #   assert_equal(expected, expectation)
  # end

  # def test_variance
  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   var = moran.variance
  #   expected = 0.0671875
  #   assert_in_delta(expected, var, 0.005)
  # end

  # def test_z_score
  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   var = moran.z_score
  #   expected = -3.375
  #   assert_in_delta(expected, var, 0.05)
  # end
end
