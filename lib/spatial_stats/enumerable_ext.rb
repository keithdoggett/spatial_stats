# frozen_string_literal: true

module Enumerable
  def standardize
    # standardize is (variable - mean)/stdev
    m = mean
    std = Math.sqrt(sample_variance)
    map { |v| (v - m) / std }
  end

  def mean
    sum / size.to_f
  end

  def sample_variance
    m = mean
    numerator = sum { |v| (v - m)**2 }
    numerator / (size - 1).to_f
  end
end
