# frozen_string_literal: true

require 'numo/narray'
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
    assert_equal(4, full_mat.shape[0])
    assert_equal(4, full_mat.shape[1])

    expected = Numo::DFloat[
      [0, 1, 0, 1],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [1, 0, 1, 0]
    ]
    assert_equal(expected, full_mat)
  end

  def test_standardized
    mat = SpatialStats::Weights::WeightsMatrix.new(@keys, @weights)

    standardized_mat = mat.standardized
    expected = Numo::DFloat[
      [0, 0.5, 0, 0.5],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [0.5, 0, 0.5, 0]
    ]
    assert_equal(expected, standardized_mat)
  end
end
