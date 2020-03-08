# frozen_string_literal: true

require 'test_helper'

class VariablesQueriesTest < ActiveSupport::TestCase
  def setup
    polys = Polygon.grid(0, 0, 1, 3)
    polys.each_with_index do |poly, idx|
      poly.value = idx
      poly.save
    end
  end

  def test_query_field
    scope = Polygon.all
    variables = SpatialStats::Queries::Variables
                .query_field(scope, :value)

    expectation = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
    assert_equal(expectation, variables)
  end
end
