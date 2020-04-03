# frozen_string_literal: true

require 'spatial_stats/global/stat'
require 'spatial_stats/global/bivariate_moran'
require 'spatial_stats/global/moran'

module SpatialStats
  ##
  # The Global module provides functionality for global spatial statistics.
  # Global spatial statistics describe the entire dataset with one value,
  # like how clustered the observations are across the entire dataset.
  #
  # All global classes define a +stat+ method that returns the described
  # statistic and an +mc+ method that runs a permutation test determine a
  # pseudo p-value for the statistic. Some also define +variance+ and
  # +z_score+  methods that can be used to calculate p-values if the
  # distribution is known.
  module Global
  end
end
