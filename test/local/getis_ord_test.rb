# frozen_string_literal: true

require 'test_helper'

class LocalGetisOrdTest < ActiveSupport::TestCase
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

  def test_star_without_diag
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    refute g.star?
  end

  def test_star_with_diag
    neighbors = {
      1 => [{ id: 1, weight: 1 }, { id: 2, weight: 1 }],
      2 => [{ id: 1, weight: 1 }, { id: 2, weight: 1 }]
    }
    weights = SpatialStats::Weights::WeightsMatrix.new(neighbors)
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, weights)

    assert g.star?
  end

  def test_x
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    x = g.x
    expected = @values
    assert_equal(expected, x)
  end

  def test_stat
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    gi = g.stat
    expected_i = [0.25, 0, 0.25, 0, 0.25, 0, 0.25, 0, 0.25]
    gi.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_stat_star
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights, true)
    gi = g.stat
    expected_gi = [0.16666, 0.0625, 0.16666, 0.0625, 0.2,
                   0.0625, 0.16666, 0.0625, 0.16666]
    gi.each_with_index do |v, idx|
      assert_in_delta(expected_gi[idx], v, 1e-5)
    end
  end

  def test_stat_clustered
    # replace bottom 2 rows values with 1, top row with 0
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    gi = g.stat
    expected_gi = [0.2, 0.2, 0.2, 0.1333333, 0.15, 0.1333333,
                   0.0833333, 0.055556, 0.0833333]

    gi.each_with_index do |v, idx|
      assert_in_delta(expected_gi[idx], v, 1e-5)
    end
  end

  def test_quads
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    quads = g.quads
    expected = %w[LH HL LH HL LH HL LH HL LH]
    assert_equal(expected, quads)
  end

  def test_mc
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_vals = g.mc(999, seed)

    expected = [0.216, 0.001, 0.224, 0.001, 0.02, 0.001, 0.224, 0.001, 0.215]

    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end

  def test_mc_clustered
    # run this test to make sure the p value calculation still works
    # for cases where the result is always positive.
    # If we only go on the >= comparison, it ignores the fact that
    # something could be very significantly low and end up with PVals
    # > 95. Have to perform a swap on those and essentially do 1 - p.
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_vals = g.mc(999, seed)

    expected = [0.343, 0.187, 0.355, 0.28, 0.477, 0.289, 0.031, 0.001, 0.039]
    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end

  def test_groups
    g = SpatialStats::Local::GetisOrd.new(@poly_scope, :value, @weights)
    groups = g.groups
    expected = %w[L H L H L H L H L]
    assert_equal(expected, groups)
  end
end
