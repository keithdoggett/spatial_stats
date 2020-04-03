# frozen_string_literal: true

require 'spatial_stats/local/stat'
require 'spatial_stats/local/bivariate_moran'
require 'spatial_stats/local/geary'
require 'spatial_stats/local/getis_ord'
require 'spatial_stats/local/moran'
require 'spatial_stats/local/multivariate_geary'

module SpatialStats
  ##
  # The Local module provides functionality for local spatial statistics.
  # Local spatial statistics describe each location in the dataset with a value,
  # like how similar or dissimilar each area is to its neighbors.
  #
  # All local classes define a +stat+ method that returns the described
  # statistic and an +mc+ method that runs a permutation test determine a
  # pseudo p-value for the statistic. Some also define +variance+ and
  # +z_score+  methods that can be used to calculate p-values if the
  # distribution is known.
  module Local
  end
end
