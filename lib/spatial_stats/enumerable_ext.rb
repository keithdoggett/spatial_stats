# frozen_string_literal: true

##
# Extension to the Enumerable module
module Enumerable
  ##
  # Standardize works with a numeric array and transforms each value so that
  # the mean is 0 and the variance is 1.
  # Formula is (x - mean)/stdev
  #
  # @example
  #   [1,2,3].standardize
  #   [-1.0, 0.0, 1.0]
  #
  # @return [Array] the standardized array
  def standardize
    # standardize is (variable - mean)/stdev
    m = mean
    std = Math.sqrt(sample_variance)
    map { |v| (v - m) / std }
  end

  ##
  # Mean works with a numeric array and returns the arithmetic mean.
  #
  # @example
  #   [1,2,3].mean
  #   2.0
  #
  # @return [Float] the arithmetic mean
  def mean
    sum / size.to_f
  end

  ##
  # Sample Variance works with a numeric array and returns the variance.
  # Formula for variance is (x - mean)**2/(n - 1)
  #
  # @example
  #   [1,2,3].sample_variance
  #   1.0
  #
  # @return [Float] the sample variance
  def sample_variance
    m = mean
    numerator = sum { |v| (v - m)**2 }
    numerator / (size - 1).to_f
  end
end
