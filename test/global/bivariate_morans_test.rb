# frozen_string_literal: true

class GlobalBivariateMoransTest < ActiveSupport::TestCase
  def setup
    polys = Polygon.grid(0, 0, 1, 3)

    # checkerboard will give < 0 I value
    @values = [0, 1, 0, 1, 0, 1, 0, 1, 0]
    @second_values = [1, 2, 2, 1, 2, 2, 1, 2, 2]
    polys.each_with_index do |poly, i|
      poly.value = @values[i]
      poly.second_value = @second_values[i]
      poly.save
    end

    @poly_scope = Polygon.all
    @weights = SpatialStats::Weights::Contiguous.rook_weights(@poly_scope, :geom)
  end

  def test_x_vars
    moran = SpatialStats::Global::BivariateMorans
            .new(@poly_scope, :value, :second_value, @weights)
    vars = moran.x_vars
    expected = @values.standardize
    assert_equal(expected, vars)
  end

  def test_y_vars
    moran = SpatialStats::Global::BivariateMorans
            .new(@poly_scope, :value, :second_value, @weights)
    vars = moran.y_vars
    expected = @second_values.standardize
    assert_equal(expected, vars)
  end

  def test_i
    moran = SpatialStats::Global::BivariateMorans
            .new(@poly_scope, :value, :second_value, @weights)
    i = moran.i
    expected_i = -0.0878410461157883
    assert_equal(expected_i, i)
  end

  # def test_i_clustered
  #   # replace bottom 2 rows values with 1, top row with 0
  #   values = [1, 1, 1, 1, 1, 1, 0, 0, 0]
  #   Polygon.all.each_with_index do |poly, i|
  #     poly.value = values[i]
  #     poly.save
  #   end

  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   i = moran.i
  #   assert i.positive?
  # end

  # def test_expectation
  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   expectation = moran.expectation
  #   expected = -1.0 / 8
  #   assert_equal(expected, expectation)
  # end

  # def test_variance
  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   var = moran.variance
  #   expected = 0.0671875
  #   assert_in_epsilon(expected, var, 0.0005)
  # end

  # def test_z_score
  #   moran = SpatialStats::Global::Morans.new(@poly_scope, :value, @weights)
  #   var = moran.z_score
  #   expected = -3.375
  #   assert_in_epsilon(expected, var, 0.0005)
  # end
end
