# frozen_string_literal: true

require 'numo/narray'
require 'test_helper'

class WeightsMatrixTest < ActiveSupport::TestCase
  def setup
    @keys = [1, 2, 3, 4]
    @weights = {
      1 => [{ id: 2, weight: 1 }, { id: 4, weight: 1 }],
      2 => [{ id: 1, weight: 1 }],
      3 => [{ id: 4, weight: 1 }],
      4 => [{ id: 1, weight: 1 }, { id: 3, weight: 1 }]
    }
  end

  def test_initialize
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)

    assert_equal(@keys, mat.keys)
    assert_equal(@weights, mat.weights)
  end

  def test_equality_operator_true
    mat1 = SpatialStats::Weights::WeightsMatrix.new(@weights)
    mat2 = SpatialStats::Weights::WeightsMatrix.new(@weights)
    assert_equal(mat1, mat2)
  end

  def test_equality_operator_false
    weights2 = {
      1 => [{ id: 2, weight: 1 }],
      2 => [{ id: 1, weight: 1 }],
      3 => [{ id: 4, weight: 1 }],
      4 => [{ id: 3, weight: 1 }]
    }
    mat1 = SpatialStats::Weights::WeightsMatrix.new(@weights)
    mat2 = SpatialStats::Weights::WeightsMatrix.new(weights2)
    assert_not_equal(mat1, mat2)
  end

  def test_dense
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)

    dense_mat = mat.dense
    assert_equal(4, dense_mat.shape[0])
    assert_equal(4, dense_mat.shape[1])

    expected = Numo::DFloat[
      [0, 1, 0, 1],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [1, 0, 1, 0]
    ]
    assert_equal(expected, dense_mat)
  end

  def test_sparse
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)

    expected = SpatialStats::Weights::CSRMatrix.new(@weights, 4)

    result = mat.sparse
    assert_equal(expected.values, result.values)
    assert_equal(expected.col_index, result.col_index)
    assert_equal(expected.row_index, result.row_index)
  end

  def test_wc
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)
    expected = [2, 1, 1, 2]

    result = mat.wc
    assert_equal(expected, result)
  end

  def test_standardize
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)
    standardized_mat = mat.standardize

    expected = {
      1 => [{ id: 2, weight: 1.0 / 2 }, { id: 4, weight: 1.0 / 2 }],
      2 => [{ id: 1, weight: 1 }],
      3 => [{ id: 4, weight: 1 }],
      4 => [{ id: 1, weight: 1.0 / 2 }, { id: 3, weight: 1.0 / 2 }]
    }
    assert_equal(expected, standardized_mat.weights)
  end

  def test_window
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)
    windowed_mat = mat.window

    expected = {
      1 => [{ id: 1, weight: 1 }, { id: 2, weight: 1 }, { id: 4, weight: 1 }],
      2 => [{ id: 1, weight: 1 }, { id: 2, weight: 1 }],
      3 => [{ id: 3, weight: 1 }, { id: 4, weight: 1 }],
      4 => [{ id: 1, weight: 1 }, { id: 3, weight: 1 }, { id: 4, weight: 1 }]
    }
    assert_equal(expected, windowed_mat.weights)
  end

  def test_with_string_key
    keys = %w[a b c d]
    weights = {
      'a' => [{ id: 'b', weight: 1 }, { id: 'd', weight: 1 }],
      'b' => [{ id: 'a', weight: 1 }],
      'c' => [{ id: 'd', weight: 1 }],
      'd' => [{ id: 'a', weight: 1 }, { id: 'c', weight: 1 }]
    }

    mat = SpatialStats::Weights::WeightsMatrix.new(weights)

    assert_equal(keys, mat.keys)
    assert_equal(weights, mat.weights)

    dense_mat = mat.dense
    assert_equal(4, dense_mat.shape[0])
    assert_equal(4, dense_mat.shape[1])

    expected = Numo::DFloat[
      [0, 1, 0, 1],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [1, 0, 1, 0]
    ]
    assert_equal(expected, dense_mat)
  end

  def test_with_sym_key
    keys = %w[a b c d]
    weights = {
      a: [{ id: :b, weight: 1 }, { id: :d, weight: 1 }],
      b: [{ id: :a, weight: 1 }],
      c: [{ id: :d, weight: 1 }],
      d: [{ id: :a, weight: 1 }, { id: :c, weight: 1 }]
    }

    mat = SpatialStats::Weights::WeightsMatrix.new(weights)

    assert_equal(keys.map(&:to_sym), mat.keys)
    assert_equal(weights, mat.weights)

    dense_mat = mat.dense
    assert_equal(4, dense_mat.shape[0])
    assert_equal(4, dense_mat.shape[1])

    expected = Numo::DFloat[
      [0, 1, 0, 1],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [1, 0, 1, 0]
    ]
    assert_equal(expected, dense_mat)
  end
end
