class CreateExternalBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :external_blocks do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :source, null: false, default: "admin"
      t.string :external_event_id
      t.datetime :start_utc, null: false
      t.datetime :end_utc, null: false

      t.timestamps
    end
    add_index :external_blocks, [:provider_id, :start_utc, :end_utc]
  end
end
