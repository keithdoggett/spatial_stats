# frozen_string_literal: true

class Polygon < ApplicationRecord
  @@factory = RGeo::Cartesian.factory

  def self.factory
    @@factory = if RGeo::Geos.supported?
      RGeo::Geos.factory
    else
      RGeo::Cartesian.factory
    end
  end

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
    linear_ring = self.factory.linear_ring(points)
    polygon = self.factory.polygon(linear_ring)
    new(geom: polygon)
  end

  def centroid
    # simple centroid method
    # returns point at center
    if RGeo::Geos.supported?
      geom.centroid
    else
      x = 0.0
      y = 0.0
      pts = geom.coordinates[0]
      pts.pop # get rid of duplicated initial point
  
      pts.each do |pt|
        x += pt[0]
        y += pt[1]
      end
      x /= pts.size
      y /= pts.size
  
      self.class.factory.point(x, y)
    end
  end
end
