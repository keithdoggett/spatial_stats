# frozen_string_literal: true

require 'matrix'
require 'test_helper'

class WeightsMatrixTest < ActiveSupport::TestCase
  def setup
    @keys = [1, 2, 3, 4]
    @weights = {
      1 => [{ j_id: 2, weight: 1 }, { j_id: 4, weight: 1 }],
      2 => [{ j_id: 1, weight: 1 }],
      3 => [{ j_id: 4, weight: 1 }],
      4 => [{ j_id: 1, weight: 1 }, { j_id: 3, weight: 1 }]
    }
  end

  def test_initialize
    mat = SpatialStats::Weights::WeightsMatrix.new(@keys, @weights)

    assert_equal(mat.keys, @keys)
    assert_equal(mat.weights, @weights)
  end

  def test_full
    mat = SpatialStats::Weights::WeightsMatrix.new(@keys, @weights)

    full_mat = mat.full
    assert_equal(4, full_mat.row_count)
    assert_equal(4, full_mat.column_count)

    expected = Matrix[
      [0, 1, 0, 1],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [1, 0, 1, 0]
    ]
    assert_equal(expected, full_mat)
  end
end
