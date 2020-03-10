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
    z.each_with_index.map do |v, idx|
      assert_in_delta(expected_z[idx], v, 1e-5)
    end
  end

  def test_i
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    i = moran.i
    expected_i = [-0.888888888888889, -0.8888888888888888, -0.888888888888889,
                  -0.8888888888888888, -0.888888888888889, -0.8888888888888888,
                  -0.888888888888889, -0.8888888888888888, -0.888888888888889]
    i.each_with_index.map do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
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

    i.each_with_index.map do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_expectation
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    expectation = moran.expectation
    expected = -1.0 / 8
    assert_equal(expected, expectation)
  end

  def test_variance
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    var = moran.variance
    expected_variance = [0.6961309523809524, 0.511061507936508,
                         0.6961309523809524, 0.511061507936508,
                         0.4185267857142857, 0.511061507936508,
                         0.6961309523809524, 0.511061507936508,
                         0.6961309523809524]
    var.each_with_index.map do |v, i|
      assert_in_delta(expected_variance[i], v, 1e-5)
    end
  end

  def test_z_score
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    z_scores = moran.z_score
    expected_z_scores = [-0.91555559, -1.06854695, -0.91555559, -1.06854695,
                         -1.18077885, -1.06854695, -0.91555559, -1.06854695,
                         -0.91555559]
    z_scores.each_with_index.map do |v, idx|
      assert_in_delta(expected_z_scores[idx], v, 1e-5)
    end
  end

  def test_quads
    moran = SpatialStats::Local::Morans.new(@poly_scope, :value, @weights)
    quads = moran.quads
    expected = %w[LH HL LH HL LH HL LH HL LH]
    assert_equal(expected, quads)
  end
end
