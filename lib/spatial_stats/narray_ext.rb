# frozen_string_literal: true

require 'numo/narray'

module Numo
  ##
  # Extension to Numo::NArray base class.
  class NArray
    ##
    # For a 2-D NArray, change the non-zero values so that the sum of each row
    # is 1.
    #
    # @ example
    #
    #   Numo::DFloat [[0,1,1], [1,1,1]].row_standardized
    #   Numo::DFloat [[0,0.5,0.5], [0.33333,0.33333,0.33333]]
    #
    # @return [Numo::NArray]
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
