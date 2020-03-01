class CreatePointModels < ActiveRecord::Migration[6.0]
  def change
    create_table :point_models do |t|
      t.st_point :position
      t.float :value
      
      t.timestamps
    end
  end
end
