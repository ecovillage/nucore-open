class ChangeAccountFacilityRelationship144419 < ActiveRecord::Migration[5.0]
  def up
    create_table :account_facility_joins do |t|
      t.references :facility, index: true, null: false, foreign_key: true
      t.references :account, index: true, null: false, foreign_key: true
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.datetime :deleted_at
      t.timestamps
    end

    execute <<~SQL
      INSERT INTO account_facility_joins
      (account_id, facility_id, created_by_id, created_at, updated_at)
      SELECT id, facility_id, created_by, created_at, updated_at
      FROM accounts
      WHERE facility_id IS NOT NULL
    SQL

  end

  def down
    drop_table :account_facility_joins
  end

end
