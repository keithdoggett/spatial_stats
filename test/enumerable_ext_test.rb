# frozen_string_literal: true

require 'test_helper'

class EnumerableExtTest < ActiveSupport::TestCase
  def setup
    @array = [0, 1, 0, 1, 0, 1, 0, 1, 0]
  end

  def test_standardize
    expected = [-0.843274, 1.05409, -0.843274, 1.05409, -0.843274,
                1.05409, -0.843274, 1.05409, -0.843274]
    result = @array.standardize

    result.each_with_index do |val, i|
      assert_in_delta(val, expected[i], 0.0005)
    end
  end
end
