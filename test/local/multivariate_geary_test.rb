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

  def test_i
    geary = SpatialStats::Local::MultivariateGeary.new(@poly_scope, %i[value second_value], @weights)
    i = geary.i
    expected_i = [2.8, 2.466667, 1.8, 2.466667, 2.3,
                  1.8, 2.8, 2.466667, 1.8]
    i.each_with_index do |v, idx|
      assert_in_delta(expected_i[idx], v, 1e-5)
    end
  end
end
