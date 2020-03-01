class CreatePolygonModels < ActiveRecord::Migration[6.0]
  def change
    create_table :polygon_models do |t|
      t.st_polygon :geom
      t.float :value

      t.timestamps
    end
  end
end
