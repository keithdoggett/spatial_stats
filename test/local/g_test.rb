# frozen_string_literal: true

require 'test_helper'

class LocalGTest < ActiveSupport::TestCase
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
    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights)
    refute g.star?
  end

  def test_star_with_diag
    neighbors = {
      1 => [{ j_id: 1, weight: 1 }, { j_id: 2, weight: 1 }],
      2 => [{ j_id: 1, weight: 1 }, { j_id: 2, weight: 1 }]
    }
    weights = SpatialStats::Weights::WeightsMatrix.new([1, 2], neighbors)
    g = SpatialStats::Local::G.new(@poly_scope, :value, weights)

    assert g.star?
  end

  def test_x
    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights)
    x = g.x
    expected = @values
    assert_equal(expected, x)
  end

  def test_i
    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights)
    i = g.i
    expected_i = [0.25, 0, 0.25, 0, 0.25, 0, 0.25, 0, 0.25]
    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_i_star
    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights, true)
    i = g.i
    expected_i = [0.16666, 0.0625, 0.16666, 0.0625, 0.2,
                  0.0625, 0.16666, 0.0625, 0.16666]
    i.each_with_index do |v, idx|
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

    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights)
    i = g.i
    expected_i = [0.2, 0.2, 0.2, 0.1333333, 0.15, 0.1333333,
                  0.0833333, 0.055556, 0.0833333]

    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_quads
    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights)
    quads = g.quads
    expected = %w[LH HL LH HL LH HL LH HL LH]
    assert_equal(expected, quads)
  end

  def test_mc
    g = SpatialStats::Local::G.new(@poly_scope, :value, @weights)
    seed = 123_456
    p_vals = g.mc(999, seed)
    expected = [0.223, 0.162, 0.219, 0.168, 0.023, 0.187, 0.232, 0.193, 0.204]

    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end
end
