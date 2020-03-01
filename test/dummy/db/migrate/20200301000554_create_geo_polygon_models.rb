class CreateGeoPolygonModels < ActiveRecord::Migration[6.0]
  def change
    create_table :geo_polygon_models do |t|
      t.st_polygon :geom, geographic: true
      t.float :value

      t.timestamps
    end
  end
end
