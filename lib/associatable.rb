require_relative '02_searchable'
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
  # Phase IIIb
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

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
