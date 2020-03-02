# frozen_string_literal: true

class CreatePoints < ActiveRecord::Migration[6.0]
  def change
    create_table :points do |t|
      t.st_point :position
      t.float :value

      t.timestamps
    end
  end
end
