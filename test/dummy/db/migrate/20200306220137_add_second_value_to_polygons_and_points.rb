# frozen_string_literal: true

class AddSecondValueToPolygonsAndPoints < ActiveRecord::Migration[6.0]
  def change
    add_column :polygons, :second_value, :float
    add_column :points, :second_value, :float
  end
end
