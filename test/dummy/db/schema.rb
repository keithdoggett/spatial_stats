# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_06_220137) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "geo_points", force: :cascade do |t|
    t.geography "latlon", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.float "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "geo_polygons", force: :cascade do |t|
    t.geography "geom", limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
    t.float "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "points", force: :cascade do |t|
    t.geometry "position", limit: {:srid=>0, :type=>"st_point"}
    t.float "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "second_value"
  end

  create_table "polygons", force: :cascade do |t|
    t.geometry "geom", limit: {:srid=>0, :type=>"st_polygon"}
    t.float "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "second_value"
  end

end
