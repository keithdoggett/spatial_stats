# frozen_string_literal: true

require 'test_helper'

class NArrayExtTest < ActiveSupport::TestCase
  def setup
    @matrix = Numo::DFloat[[0, 1, 0], [1, 0, 1], [0, 1, 0]]
  end

  def test_row_standardize
    expected = Numo::DFloat[[0, 1, 0], [1.0 / 2, 0, 1.0 / 2], [0, 1, 0]]
    result = @matrix.row_standardize
    assert_equal(expected, result)
  end

  def test_row_standardize_zeros
    zero_matrix = Numo::DFloat[[0, 1, 0], [1, 0, 1], [0, 0, 0]]
    expected = Numo::DFloat[[0, 1, 0], [1.0 / 2, 0, 1.0 / 2], [0, 0, 0]]
    result = zero_matrix.row_standardize
    assert_equal(expected, result)
  end

  def test_window_success
    expected = Numo::DFloat[[1, 1, 0], [1, 1, 1], [0, 1, 1]]
    result = @matrix.window
    assert_equal(expected, result)
  end

  def test_window_failure
    # will fail if the trace isn't already 0 and just return input
    input = Numo::DFloat[[1, 1, 0], [1, 0, 1], [0, 1, 0]]
    result = input.window
    assert_equal(input, result)
  end
end
