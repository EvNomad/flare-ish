class CreateWeeklyTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_templates do |t|
      t.references :provider, null: false, foreign_key: true
      t.integer :dow, null: false
      t.time :start_local, null: false
      t.time :end_local, null: false

      t.timestamps
    end

    add_index :weekly_templates, [:provider_id, :dow]
  end
end
