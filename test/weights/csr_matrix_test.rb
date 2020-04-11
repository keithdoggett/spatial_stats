# frozen_string_literal: true

require 'test_helper'

class CSRMatrixTest < ActiveSupport::TestCase
  def setup
    @values = [0, 0, 1, 0, 1, 0, 1, 0, 0]
    @m = 3
    @n = 3
  end

  def test_initialize_success
    csr = SpatialStats::Weights::CSRMatrix.new(@values, @m, @n)

    assert_equal(3, csr.m)
    assert_equal(3, csr.n)
    assert_equal(3, csr.nnz)
  end

  def test_initialize_failure
    assert_raises(ArgumentError) do
      SpatialStats::Weights::CSRMatrix.new([], @m, @n)
    end
  end

  def test_values
    csr = SpatialStats::Weights::CSRMatrix.new(@values, @m, @n)
    expected = [1, 1, 1]

    assert_equal(expected, csr.values)
  end

  def test_col_index
    csr = SpatialStats::Weights::CSRMatrix.new(@values, @m, @n)
    expected = [2, 1, 0]

    assert_equal(expected, csr.col_index)
  end

  def test_row_index
    csr = SpatialStats::Weights::CSRMatrix.new(@values, @m, @n)
    expected = [0, 1, 2, 3]

    assert_equal(expected, csr.row_index)
  end

  def test_mulvec_succes
    csr = SpatialStats::Weights::CSRMatrix.new(@values, @m, @n)
    vec = [1, 2, 3]
    expected = [3, 2, 1]

    assert_equal(expected, csr.mulvec(vec))
  end

  def test_mulvec_failure
    csr = SpatialStats::Weights::CSRMatrix.new(@values, @m, @n)
    vec = [1, 2, 3, 4]

    assert_raises(ArgumentError) { csr.mulvec(vec) }
  end
end
