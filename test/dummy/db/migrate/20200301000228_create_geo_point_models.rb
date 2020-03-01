class CreateGeoPointModels < ActiveRecord::Migration[6.0]
  def change
    create_table :geo_point_models do |t|
      t.st_point :latlon, geographic: true
      t.float :value

      t.timestamps
    end
  end
end
