# Workspaces: every test plan, bug and bug analysis belongs to one project.
# Existing data moves into a "Projeto padrão" project.
class CreateProjects < ActiveRecord::Migration[8.1]
  OWNED = %i[test_plans bugs bug_analyses].freeze

  def up
    create_table :projects do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, foreign_key: true
      t.timestamps
    end
    add_index :projects, :name, unique: true

    OWNED.each { |table| add_reference table, :project, foreign_key: true }

    if OWNED.any? { |table| select_value("SELECT 1 FROM #{table} LIMIT 1") }
      now = connection.quote(Time.current)
      execute "INSERT INTO projects (name, created_at, updated_at) VALUES ('Projeto padrão', #{now}, #{now})"
      project_id = select_value("SELECT id FROM projects WHERE name = 'Projeto padrão'")
      OWNED.each { |table| execute "UPDATE #{table} SET project_id = #{project_id}" }
    end

    OWNED.each { |table| change_column_null table, :project_id, false }
  end

  def down
    OWNED.each { |table| remove_reference table, :project, foreign_key: true }
    drop_table :projects
  end
end
