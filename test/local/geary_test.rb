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

  def test_i
    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    i = geary.i
    expected_i = [3.6, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6, 3.6]
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

    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    i = geary.i
    expected_i = [0, 0, 0, 1.3333333333333333,
                  1.0, 1.3333333333333333, 2.0, 1.3333333333333333, 2]

    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end

  def test_quads
    geary = SpatialStats::Local::Geary.new(@poly_scope, :value, @weights)
    quads = geary.quads
    expected = %w[LH HL LH HL LH HL LH HL LH]
    assert_equal(expected, quads)
  end
end
