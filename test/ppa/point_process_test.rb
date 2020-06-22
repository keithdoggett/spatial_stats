# frozen_string_literal: true

require 'test_helper'

class PointProcessTest < ActiveSupport::TestCase
  def setup
    @bbox = [[-0.5, -0.5], [0.5, 0.5]]
    seed = 123_456
    Kernel.srand(seed)
  end

  def test_generate_from_n
    n = 20
    result = SpatialStats::PPA::PointProcess.generate_from_n(@bbox, n)
    assert_equal(n, result.size)

    result.each do |point|
      assert_includes(-0.5..0.5, point[0])
      assert_includes(-0.5..0.5, point[1])
    end
  end

  def test_generate_from_lambda
    lam = 20
    result = SpatialStats::PPA::PointProcess.generate_from_lambda(@bbox, lam)

    result.each do |point|
      assert_includes(-0.5..0.5, point[0])
      assert_includes(-0.5..0.5, point[1])
    end
  end
end
