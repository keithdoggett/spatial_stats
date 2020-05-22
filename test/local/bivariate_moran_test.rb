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
    @weights = SpatialStats::Weights::Contiguous.rook(@poly_scope, :geom)
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

  def test_y=
    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    moran.y = @second_values
    expected = @second_values.standardize
    assert_equal(expected, moran.y)
  end

  def test_stat
    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    i = moran.stat
    expected_i = [0.281091, 0, -0.562183, -0.702728, -0.140546,
                  0.702728, 0.281091, 0, -0.562183]
    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_mc
    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    seed = 123_456_789
    p_vals = moran.mc(999, seed)
    expected = [0.461, 0.807, 0.348, 0.106, 0.485, 0.182, 0.474, 0.82, 0.354]

    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end

  def test_groups
    second_values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    @poly_scope.each_with_index do |poly, i|
      poly.second_value = second_values[i]
      poly.save
    end

    moran = SpatialStats::Local::BivariateMoran.new(@poly_scope, :value, :second_value, @weights)
    groups = moran.groups
    expected = %w[LH HH LH HH LH HH LL HL LL]
    assert_equal(expected, groups)
  end
end
