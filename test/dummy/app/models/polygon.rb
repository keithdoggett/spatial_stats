# frozen_string_literal: true

class Polygon < ApplicationRecord
  @@factory = RGeo::Geos.factory

  def self.grid(x, y, len, size)
    # returns an array of squares as a grid
    # do rows, then columns
    xs = []
    ys = []
    size.times do |i|
      xs << x + (i * len)
      ys << y + (i * len)
    end

    grid = xs.product(ys).map do |pt|
      new_from_square(pt[0], pt[1], len)
    end
    grid
  end

  def self.new_from_square(x, y, len)
    xs = [x, x + len]
    ys = [y, y + len]

    corners = [
      [xs[0], ys[0]],
      [xs[1], ys[0]],
      [xs[1], ys[1]],
      [xs[0], ys[1]]
    ]
    points = corners.map { |pt| @@factory.point(pt[0], pt[1]) }
    linear_ring = @@factory.linear_ring(points)
    polygon = @@factory.polygon(linear_ring)
    new(geom: polygon)
  end
end
