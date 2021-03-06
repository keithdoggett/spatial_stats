# frozen_string_literal: true

require 'test_helper'

class LocalMoranTest < ActiveSupport::TestCase
  def setup
    polys = Polygon.grid(0, 0, 1, 3)

    @values = [0, 1, 0, 1, 0, 1, 0, 1, 0]
    polys.each_with_index do |poly, i|
      poly.value = @values[i]
      poly.save
    end

    @poly_scope = Polygon.all
    @weights = SpatialStats::Weights::Contiguous.rook(@poly_scope, :geom)
  end

  def test_from_observations
    moran = SpatialStats::Local::Moran.from_observations(@values, @weights)

    assert_equal(moran.x, @values.standardize)
    assert_equal(moran.weights, @weights.standardize)
  end

  def test_from_observations_error
    assert_raises(ArgumentError) do
      SpatialStats::Local::Moran.from_observations([], @weights)
    end
  end

  def test_x
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    x = moran.x
    expected = @values.standardize
    assert_equal(expected, x)
  end

  def test_x=
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    moran.x = @values
    expected = @values.standardize
    assert_equal(expected, moran.x)
  end

  def test_z
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    z = moran.z
    expected_z = [-0.8432740427115678, 1.0540925533894598, -0.8432740427115678,
                  1.0540925533894598, -0.8432740427115678,
                  1.0540925533894598, -0.8432740427115678,
                  1.0540925533894598, -0.8432740427115678]
    z.each_with_index do |v, i|
      assert_in_delta(expected_z[i], v, 1e-5)
    end
  end

  def test_stat
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    i = moran.stat
    expected_i = [-0.888888888888889, -0.8888888888888888, -0.888888888888889,
                  -0.8888888888888888, -0.888888888888889, -0.8888888888888888,
                  -0.888888888888889, -0.8888888888888888, -0.888888888888889]

    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_stat_clustered
    # replace bottom 2 rows values with 1, top row with 0
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)

    # these should all be slightly positive, or zero for the corners
    # this is the same output as the test from GeoDa
    i = moran.i
    expected_i = [0.4444444444444444, 0.4444444444444444, 0.4444444444444444,
                  0.0, 0.11111111111111112, 0.0, 0.4444444444444444,
                  0.8888888888888888, 0.4444444444444444]

    i.each_with_index do |v, i|
      assert_in_delta(expected_i[i], v, 1e-5)
    end
  end

  def test_expectation
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    expectation = moran.expectation
    expected = -1.0 / 8
    assert_equal(expected, expectation)
  end

  def test_variance
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    var = moran.variance
    expected_variance = [0.6961309523809524, 0.511061507936508,
                         0.6961309523809524, 0.511061507936508,
                         0.4185267857142857, 0.511061507936508,
                         0.6961309523809524, 0.511061507936508,
                         0.6961309523809524]
    var.each_with_index do |v, i|
      assert_in_delta(expected_variance[i], v, 1e-5)
    end
  end

  def test_z_score
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    z_scores = moran.z_score
    expected_z_scores = [-0.91555559, -1.06854695, -0.91555559, -1.06854695,
                         -1.18077885, -1.06854695, -0.91555559, -1.06854695,
                         -0.91555559]
    z_scores.each_with_index do |v, i|
      assert_in_delta(expected_z_scores[i], v, 1e-5)
    end
  end

  def test_quads
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    quads = moran.quads
    expected = %w[LH HL LH HL LH HL LH HL LH]
    assert_equal(expected, quads)
  end

  def test_crand
    # test value will be held in crand
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    rands = moran.crand(9, Random.new)

    assert_equal(9, rands.shape[0])
    assert_equal(5, rands.shape[1])
  end

  def test_mc
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_vals = moran.mc(999, seed)
    expected = [0.216, 0.165, 0.224, 0.184, 0.02, 0.17, 0.224, 0.195, 0.215]

    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end

  def test_summary
    moran = SpatialStats::Local::Moran.new(@poly_scope, :value, @weights)
    seed = 123_456
    summary = moran.summary(999, seed)

    assert_equal(9, summary.size)
    assert summary[0].key?(:key)
    assert summary[0].key?(:stat)
    assert summary[0].key?(:p)
    assert summary[0].key?(:group)
  end
end
