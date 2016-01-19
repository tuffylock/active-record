require 'sqlite3'

class DBConnection
  def self.open(db_file_name)
    @db = SQLite3::Database.new(db_file_name)
    @db.results_as_hash = true
    @db.type_translation = true

    @db
  end

  def self.reset(db_file, sql_file)
    commands = [
      "rm '#{db_file}'",
      "cat '#{sql_file}' | sqlite3 '#{db_file}'"
    ]

    commands.each { |command| `#{command}` }
    DBConnection.open(db_file)
  end

  def self.instance
    raise "uninitialized database connection" if @db.nil?

    @db
  end

  def self.execute(*args)
    puts args[0]

    instance.execute(*args)
  end

  def self.execute2(*args)
    puts args[0]

    instance.execute2(*args)
  end

  def self.get_first_row(*args)
    instance.get_first_row(*args)
  end

  def self.last_insert_row_id
    instance.last_insert_row_id
  end

  private

  def initialize(db_file_name)
  end
end
