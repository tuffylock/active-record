require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      foreign_key: "#{name.to_s.underscore}_id".to_sym,
      primary_key: :id
    }

    options = defaults.merge(options)

    options.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: name.to_s.singularize.camelcase,
      foreign_key: "#{self_class_name.to_s.underscore}_id".to_sym,
      primary_key: :id
    }

    options = defaults.merge(options)

    options.each do |key, val|
      instance_variable_set("@#{key}", val)
    end
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options

    define_method(name) do
      target_class = options.model_class
      foreign_key = self.send("#{options.foreign_key}")
      primary_key = options.primary_key

      return nil if foreign_key.nil?

      target_class.where(primary_key => foreign_key).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      target_class = options.model_class
      foreign_key = options.foreign_key
      primary_key = self.send("#{options.primary_key}")

      target_class.where(foreign_key => primary_key)
    end
  end

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

  def assoc_options
    @assoc_options ||= {}
  end
end
