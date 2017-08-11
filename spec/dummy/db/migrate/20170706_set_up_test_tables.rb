class SetUpTestTables < ActiveRecord::Migration[5.1]
  def up
    create_table :teachers, force: true do |t|
      t.belongs_to  :department, index: true, foreign_key: true
      t.string      :name,       null: false
      t.string      :kind,       null: false
      t.boolean     :tenured,    null: false
      t.timestamps
    end

    create_table :students, force: true do |t|
      t.belongs_to :major,       index: true, foreign_key: true
      t.string     :name,        null: false
      t.integer    :grade,       null: false
      t.timestamps
    end

    create_table :departments, force: true do |t|
      t.string   :name,          null: false
      t.timestamps
    end

    create_table :majors, force: true do |t|
      t.belongs_to  :department, index: true, foreign_key: true
      t.string      :name,       null: false
      t.timestamps
    end

    create_table :immutable_model_with_creators, :force => true do |t|
      t.string :uuid
      t.string :name
      t.integer :created_by_id

      t.timestamps
    end

    create_table :immutable_model_with_no_creators, :force => true do |t|
      t.string :uuid
      t.string :name

      t.timestamps
    end

    create_table :users, :force => true do |t|
      t.string :name
    end
  end

  def down
    # Not actually irreversible, but there is no need to maintain this method.
    raise ActiveRecord::IrreversibleMigration
  end
end
