# frozen_string_literal: true

require 'test_helper'

class NArrayExtTest < ActiveSupport::TestCase
  def setup
    @matrix = Numo::DFloat[[0, 1, 0], [1, 0, 1], [0, 1, 0]]
  end

  def test_row_standardized
    expected = Numo::DFloat[[0, 1, 0], [1.0 / 2, 0, 1.0 / 2], [0, 1, 0]]
    result = @matrix.row_standardized
    assert_equal(expected, result)
  end

  def test_row_standardized_zeros
    zero_matrix = Numo::DFloat[[0, 1, 0], [1, 0, 1], [0, 0, 0]]
    expected = Numo::DFloat[[0, 1, 0], [1.0 / 2, 0, 1.0 / 2], [0, 0, 0]]
    result = zero_matrix.row_standardized
    assert_equal(expected, result)
  end

  def test_windowed_success
    expected = Numo::DFloat[[1, 1, 0], [1, 1, 1], [0, 1, 1]]
    result = @matrix.windowed
    assert_equal(expected, result)
  end

  def test_windowed_failure
    # will fail if the trace isn't already 0 and just return input
    input = Numo::DFloat[[1, 1, 0], [1, 0, 1], [0, 1, 0]]
    result = input.windowed
    assert_equal(input, result)
  end
end
