class CreateTimeSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :time_slots, id: :string, primary_key: :id do |t|
      t.string :tz, null: false
      t.date :local_date, null: false
      t.time :local_time, null: false
      t.datetime :start_utc, null: false
      t.datetime :end_utc, null: false
      t.integer :fold, null: false, default: 0 # 0: normal, 1: DST fall back

      t.timestamps
      
      t.index [:tz, :start_utc]
      t.index [:tz, :local_date, :local_time, :fold], unique: true, name: "index_time_slots_identity"
    end
  end
end
