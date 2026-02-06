module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def search(query)
      return all if query.blank?

      q = "%#{sanitize_sql_like(query)}%"
      table = arel_table

      conditions = []
      conditions << table[:name].matches(q).to_sql if column_names.include?("name")
      conditions << table[:title].matches(q).to_sql if column_names.include?("title")
      conditions << table[:qa_name].matches(q).to_sql if column_names.include?("qa_name")
      conditions << table[:description].matches(q).to_sql if column_names.include?("description")

      if table_name == "test_plans" || table_name == "test_scenarios"
        conditions << "tags.name LIKE :q"
      end

      return all if conditions.empty?

      if table_name == "test_plans"
        left_joins(:tags).where(conditions.join(" OR "), q: q).distinct
      else
        where(conditions.join(" OR "), q: q)
      end
    end
  end
end
