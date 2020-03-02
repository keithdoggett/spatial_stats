# frozen_string_literal: true

class CreatePolygons < ActiveRecord::Migration[6.0]
  def change
    create_table :polygons do |t|
      t.st_polygon :geom
      t.float :value

      t.timestamps
    end
  end
end
