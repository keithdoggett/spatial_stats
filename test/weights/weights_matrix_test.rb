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

  def test_full
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)

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
    mat = SpatialStats::Weights::WeightsMatrix.new(@weights)

    standardized_mat = mat.standardized
    expected = Numo::DFloat[
      [0, 0.5, 0, 0.5],
      [1, 0, 0, 0],
      [0, 0, 0, 1],
      [0.5, 0, 0.5, 0]
    ]
    assert_equal(expected, standardized_mat)
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
end
