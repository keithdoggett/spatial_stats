# frozen_string_literal: true

require 'test_helper'

class CSRMatrixTest < ActiveSupport::TestCase
  def setup
    @weights = {
      'a' => [{ id: 'c', weight: 1 }],
      'b' => [{ id: 'b', weight: 1 }],
      'c' => [{ id: 'a', weight: 1 }]
    }
    @n = 3
  end

  def test_initialize_success
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)

    assert_equal(3, csr.n)
    assert_equal(3, csr.nnz)
  end

  def test_initialize_failure
    assert_raises(ArgumentError) do
      SpatialStats::Weights::CSRMatrix.new({}, @n)
    end
  end

  def test_values
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    expected = [1, 1, 1]

    assert_equal(expected, csr.values)
  end

  def test_col_index
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    expected = [2, 1, 0]

    assert_equal(expected, csr.col_index)
  end

  def test_row_index
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    expected = [0, 1, 2, 3]

    assert_equal(expected, csr.row_index)
  end

  def test_initialize_success_neighborless
    weights = {
      'a' => [{ id: 'c', weight: 1 }],
      'b' => [{ id: 'b', weight: 1 }],
      'c' => [{ id: 'a', weight: 1 }],
      'd' => []
    }
    csr = SpatialStats::Weights::CSRMatrix.new(weights, 4)

    assert_equal(4, csr.n)
    assert_equal(3, csr.nnz)
    assert_equal([1, 1, 1], csr.values)
    assert_equal([2, 1, 0], csr.col_index)
    assert_equal([0, 1, 2, 3, 3], csr.row_index)
  end

  def test_mulvec_success
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    vec = [1, 2, 3]
    expected = [3, 2, 1]

    assert_equal(expected, csr.mulvec(vec))
  end

  def test_mulvec_failure
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    vec = [1, 2, 3, 4]

    assert_raises(ArgumentError) { csr.mulvec(vec) }
  end

  def test_dot_row_success
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    vec = [1, 2, 3]
    expected = 3

    # dot first row with vec
    assert_equal(expected, csr.dot_row(vec, 0))
  end

  def test_dot_row_failure
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    vec = [1, 2, 3, 4]

    assert_raises(ArgumentError) { csr.dot_row(vec, 0) }
  end

  def test_dot_row_failure_index
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    vec = [1, 2, 3]
    idx = 5 # out of range

    assert_raises(ArgumentError) { csr.dot_row(vec, idx) }
  end

  def test_coordinates
    csr = SpatialStats::Weights::CSRMatrix.new(@weights, @n)
    expected = {
      [0, 2] => 1,
      [1, 1] => 1,
      [2, 0] => 1
    }

    assert_equal(expected, csr.coordinates)
  end
end
