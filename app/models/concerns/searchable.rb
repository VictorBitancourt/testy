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

      extra = searchable_extra_conditions(q)
      conditions.concat(extra) if extra.any?

      return all if conditions.empty?

      scope = searchable_joins_scope
      scope.where(conditions.join(" OR "), q: q).distinct
    end

    private

    # Override in models to add extra search conditions (e.g. searching associated tables)
    def searchable_extra_conditions(_query_pattern)
      []
    end

    # Override in models to add joins needed for search
    def searchable_joins_scope
      all
    end
  end
end
