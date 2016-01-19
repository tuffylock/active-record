require_relative '03_associatable'

module Associatable
  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options =
        through_options.model_class.assoc_options[source_name]

      root_table = self.class.table_name

      through_table = through_options.table_name
      through_f_key = through_options.foreign_key
      through_p_key = through_options.primary_key

      source_table = source_options.table_name
      source_f_key = source_options.foreign_key
      source_p_key = source_options.primary_key


      target = DBConnection.execute(<<-SQL)
        SELECT
          #{source_table}.*
        FROM
          #{root_table}
        JOIN #{through_table}
          ON #{root_table}.#{through_f_key} =
                #{through_table}.#{through_p_key}
        JOIN #{source_table}
          ON #{through_table}.#{source_f_key} =
                #{source_table}.#{source_p_key}
        WHERE
          #{root_table}.id = #{self.id}
      SQL

      source_options.model_class.new(target.first)
    end
  end
end
