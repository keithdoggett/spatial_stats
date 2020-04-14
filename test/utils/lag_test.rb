# frozen_string_literal: true

require 'numo/narray'
require 'test_helper'

class LaggedVariablesTest < ActiveSupport::TestCase
  def setup
    @weights = {
      1 => [{ id: 2, weight: 1 }],
      2 => [{ id: 1, weight: 1 }, { id: 3, weight: 1 }],
      3 => [{ id: 2, weight: 1 }]
    }
    @matrix = SpatialStats::Weights::WeightsMatrix.new(@weights)
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
    weights = {
      1 => [{ id: 2, weight: 0.5 }],
      2 => [{ id: 1, weight: 0.3 }, { id: 3, weight: 0.2 }],
      3 => [{ id: 2, weight: 0.5 }]
    }
    mat = SpatialStats::Weights::WeightsMatrix.new(weights)
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
