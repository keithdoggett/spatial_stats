# frozen_string_literal: true

require 'matrix'
class Matrix
  def row_standardized
    # standardize every row to sum to 1
    standardized = row_vectors.map do |row|
      row * (1.0 / row.sum)
    end
    self.class.rows(standardized)
  end

  def windowed
    # in windowed calculations, the diagonal is set to 1
    # if trace (sum of diag) is 0, add it, else return input
    if trace.zero?
      self + self.class.identity(row_count)
    else
      self
    end
  end
end
