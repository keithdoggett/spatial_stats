# frozen_string_literal: true

require 'matrix'
require 'test_helper'

class LaggedVariablesTest < ActiveSupport::TestCase
  def setup
    @matrix = Matrix[[0, 1, 0], [1, 0, 1], [0, 1, 0]]
    @values = [1, 2, 3]
  end

  def test_neighbor_average
    expected = [2, 2, 2]
    result = SpatialStats::Utils::Lag.neighbor_average(@matrix, @values)
    assert_equal(expected, result)
  end

  def test_neighbor_sum
    expected = [2, 4, 2]
    result = SpatialStats::Utils::Lag.neighbor_sum(@matrix, @values)
    assert_equal(expected, result)
  end

  def test_neighbor_sum_idw
    mat = Matrix[[0, 0.5, 0], [0.3, 0, 0.2], [0, 0.5, 0]]
    expected = [1, 0.9, 1]
    result = SpatialStats::Utils::Lag.neighbor_sum(mat, @values)

    # round floats
    result.map! { |v| v.round(3) }
    assert_equal(expected, result)
  end

  def test_window_average
    expected = [3.0 / 2, 6.0 / 3, 5.0 / 2]
    result = SpatialStats::Utils::Lag.window_average(@matrix, @values)
    assert_equal(expected, result)
  end

  def test_window_sum
    expected = [3, 6, 5]
    result = SpatialStats::Utils::Lag.window_sum(@matrix, @values)
    assert_equal(expected, result)
  end
end
