# frozen_string_literal: true

require 'numo/narray'

module Numo
  class NArray
    def row_standardized
      # every row will sum up to 1, or if they are all 0, do nothing
      standardized = each_over_axis.map do |row|
        sum = row.sum
        if sum.zero?
          # for some reason, we have to do this instead of just returning
          # row. If row is returned, it is cast as [0,0,0] => [0,1,0] for
          # example.
          self.class.zeros(row.size)
        else
          row / sum
        end
      end
      self.class.cast(standardized)
    end

    def windowed
      # in windowed calculations, the diagonal is set to 1
      # if trace (sum of diag) is 0, add it, else return input
      if trace.zero?
        self + self.class.eye(shape[0])
      else
        self
      end
    end
  end
end
