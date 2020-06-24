# frozen_string_literal: true

require 'test_helper'
require 'rubystats'

class QuadratTest < ActiveSupport::TestCase
  def setup
    seed = 123_456
    Kernel.srand(seed)
    # generate points
    # using 1 by 1 square with 3 x divisions. Want 10 points in each division
    # for first point pattern and 30 points in the first division for the second
    # point pattern
    y_dist = Rubystats::UniformDistribution.new(0, 1.0)
    x_dist1 = Rubystats::UniformDistribution.new(0, 1.0 / 3)
    x_dist2 = Rubystats::UniformDistribution.new(1.0 / 3, 2.0 / 3)
    x_dist3 = Rubystats::UniformDistribution.new(2.0 / 3, 1.0)

    points1 = []
    10.times  { points1 << [x_dist1.rng, y_dist.rng] }
    10.times  { points1 << [x_dist2.rng, y_dist.rng] }
    10.times  { points1 << [x_dist3.rng, y_dist.rng] }

    points2 = []
    30.times { points2 << [x_dist1.rng, y_dist.rng] }

    @bbox = [[0, 0], [1, 1]]
    @pp1 = SpatialStats::PPA::PointPattern.new(points1)
    @pp2 = SpatialStats::PPA::PointPattern.new(points2)
  end

  def test_initialize
    quadrat = SpatialStats::PPA::Quadrat.new(@pp1, @bbox, 3, 1)

    assert_equal(3, quadrat.x_regions)
    assert_equal(1, quadrat.y_regions)
    assert_equal(3, quadrat.m)
  end

  def test_df
    quadrat = SpatialStats::PPA::Quadrat.new(@pp1, @bbox, 3, 1)
    result = quadrat.df
    expected = 2
    assert_equal(expected, result)
  end

  def test_expectation
    quadrat = SpatialStats::PPA::Quadrat.new(@pp1, @bbox, 3, 1)
    result = quadrat.expectation
    expected = 10
    assert_equal(expected, result)
  end

  def test_quadrat_counts
    quadrat1 = SpatialStats::PPA::Quadrat.new(@pp1, @bbox, 3, 1)
    quadrat2 = SpatialStats::PPA::Quadrat.new(@pp2, @bbox, 3, 1)

    quad1_counts = [10, 10, 10]
    quad1_result = quadrat1.quadrat_counts

    quad2_counts = [30, 0, 0]
    quad2_result = quadrat2.quadrat_counts

    assert_equal(quad1_counts, quad1_result)
    assert_equal(quad2_counts, quad2_result)
  end

  def test_quadrat_counts_grid
    bbox = [[0, 0], [3, 2]]
    points = [[0.5, 0.5], [1.5, 0.5], [2.5, 0.5],
              [0.5, 1.5], [1.5, 1.5], [2.5, 1.5]]
    pp = SpatialStats::PPA::PointPattern.new(points)
    quadrat = SpatialStats::PPA::Quadrat.new(pp, bbox, 3, 2)

    expected = [1, 1, 1, 1, 1, 1]
    assert_equal(expected, quadrat.quadrat_counts)
  end

  def test_chi2
    quadrat1 = SpatialStats::PPA::Quadrat.new(@pp1, @bbox, 3, 1)
    quadrat2 = SpatialStats::PPA::Quadrat.new(@pp2, @bbox, 3, 1)

    expected1 = 0
    quad1_chi2 = quadrat1.chi2

    expected2 = 60
    quad2_chi2 = quadrat2.chi2

    assert_equal(expected1, quad1_chi2)
    assert_equal(expected2, quad2_chi2)
  end

  def test_mc
    quadrat1 = SpatialStats::PPA::Quadrat.new(@pp1, @bbox, 3, 1)
    quadrat2 = SpatialStats::PPA::Quadrat.new(@pp2, @bbox, 3, 1)

    expected1 = 100 / 100.0
    quad1_mc = quadrat1.mc(99)

    expected2 = 1 / 100.0
    quad2_mc = quadrat2.mc(99)

    assert_equal(expected1, quad1_mc)
    assert_equal(expected2, quad2_mc)
  end

  def test_mc_quadrat
    expected = 100 / 100.0
    result = @pp1.mc_quadrat(3, 1, 99)
    assert_equal(expected, result)
  end
end
