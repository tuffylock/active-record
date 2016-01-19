module Searchable
  def where(params)
    where_input =
      params.map { |col, _| "#{col} = :#{col}" }.join(' AND ')

    results = DBConnection.execute(<<-SQL, params)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_input}
    SQL

    parse_all(results)
  end
end
