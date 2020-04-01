# frozen_string_literal: true

require 'test_helper'

class LocalGearyTest < ActiveSupport::TestCase
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

  def test_x
    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    x = geary.x
    expected = @values.standardize
    assert_equal(expected, x)
  end

  def test_stat
    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    c = geary.stat
    expected_c = [3.6, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6]
    c.each_with_index do |v, idx|
      assert_in_delta(expected_c[idx], v, 1e-5)
    end
  end

  def test_stat_clustered
    # replace bottom 2 rows values with 1, top row with 0
    values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
    Polygon.all.each_with_index do |poly, i|
      poly.value = values[i]
      poly.save
    end

    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    c = geary.stat
    expected_c = [0, 0, 0, 1.3333333333333333,
                  1.0, 1.3333333333333333, 2.0, 1.3333333333333333, 2]

    c.each_with_index do |v, idx|
      assert_in_delta(expected_c[idx], v, 1e-5)
    end
  end

  def test_quads
    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    quads = geary.quads
    expected = %w[LH HL LH HL LH HL LH HL LH]
    assert_equal(expected, quads)
  end

  def test_mc
    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_vals = geary.mc(999, seed)
    expected = [0.216, 0.165, 0.224, 0.184, 0.02, 0.17, 0.224, 0.195, 0.215]

    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end
end
