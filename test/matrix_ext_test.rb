# frozen_string_literal: true

class MatrixExtTest < ActiveSupport::TestCase
  def setup
    @matrix = Matrix[[0, 1, 0], [1, 0, 1], [0, 1, 0]]
  end

  def test_row_standardized
    expected = Matrix[[0, 1, 0], [1.0 / 2, 0, 1.0 / 2], [0, 1, 0]]
    result = @matrix.row_standardized
    assert_equal(expected, result)
  end

  def test_windowed_success
    expected = Matrix[[1, 1, 0], [1, 1, 1], [0, 1, 1]]
    result = @matrix.windowed
    assert_equal(expected, result)
  end

  def test_windowed_failure
    # will fail if the trace isn't already 0 and just return input
    input = Matrix[[1, 1, 0], [1, 0, 1], [0, 1, 0]]
    result = input.windowed
    assert_equal(input, result)
  end
end
