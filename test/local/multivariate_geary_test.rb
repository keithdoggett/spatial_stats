# frozen_string_literal: true

require 'test_helper'

class LocalMultivariateGearyTest < ActiveSupport::TestCase
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

  def test_stat
    geary = SpatialStats::Local::MultivariateGeary.new(@poly_scope, %i[value second_value], @weights)
    c = geary.stat
    expected_c = [2.8, 2.466667, 1.8, 2.466667, 2.3,
                  1.8, 2.8, 2.466667, 1.8]
    c.each_with_index do |v, idx|
      assert_in_delta(expected_c[idx], v, 1e-5)
    end
  end

  def test_mc
    geary = SpatialStats::Local::MultivariateGeary.new(@poly_scope, %i[value second_value], @weights)
    seed = 123_456
    p_vals = geary.mc(999, seed)

    expected = [0.185, 0.313, 0.345, 0.318, 0.21, 0.339, 0.32, 0.452, 0.571]
    expected.each_with_index do |v, i|
      assert_in_delta(v, p_vals[i], 0.0005)
    end
  end
end
