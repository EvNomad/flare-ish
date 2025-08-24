class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.integer :role, null: false
      t.references :client, foreign_key: true, null: true
      t.references :provider, foreign_key: true, null: true
      t.datetime :jti_valid_after, null: true

      t.timestamps
    end
    add_index :accounts, :email, unique: true
  end
end
