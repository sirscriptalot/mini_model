module MiniModel
  VERSION = '0.0.2'

  class Error < StandardError; end

  class MissingId < Error; end

  def self.included(model)
    model.extend(ClassMethods)
  end

  module ClassMethods
    def dataset
      @dataset
    end

    def dataset=(dataset)
      @dataset = dataset
    end

    # Defines an accessor for the attributes hash. The whole point
    # of the attributes hash vs. instance variables is for easily
    # passing a hash to the dataset for persistence. Maybe this is a bad
    # idea and we should use plain ol' attr_accessor and build the hash
    # when needed.
    def attribute(key, type = nil)
      reader = :"#{key}"
      writer = :"#{key}="

      define_method(reader) do
        self.attributes[reader]
      end

      define_method(writer) do |value|
        self.attributes[reader] = value
      end
    end

    def build(dataset)
      dataset.map { |attributes| new(attributes) }
    end

    # Convenience for initializin and persisting a
    # new model instance.
    def create(attributes = {})
      new(attributes).create
    end

    def [](id)
      first(id: id)
    end

    def first(*args, &block)
      attributes = dataset.first(*args, &block)

      if attributes
        new(attributes)
      else
        nil
      end
    end

    def all(&block)
      build(dataset.all(&block))
    end

    def where(*args, &block)
      build(dataset.where(*args, &block))
    end

    def to_foreign_key
      name.
        to_s.
        match(/^(?:.*::)*(.*)$/)[1].
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        downcase.
        concat('_id').
        to_sym
    end

    def children(association, model_name, foreign_key = to_foreign_key)
      define_method(association) do
        model = self.class.const_get(model_name)

        model.where(foreign_key => id)
      end
    end

    def child(association, model_name, foreign_key = to_foreign_key)
      define_method(association) do
        model = self.class.const_get(model_name)

        model.first(foreign_key => id)
      end
    end

    def parent(association, model_name, foreign_key = :"#{association}_id")
      reader = foreign_key
      writer = :"#{foreign_key}="

      define_method(reader) do
        self.attributes[reader]
      end

      define_method(writer) do |value|
        self.attributes[reader] = value
      end

      define_method(association) do
        model = self.class.const_get(model_name)

        model[send(foreign_key)]
      end

      define_method(:"#{association}=") do |value|
        if value
          send(writer, value.id)
        else
          send(writer, value)
        end
      end
    end
  end

  def initialize(attributes = {})
    self.attributes = attributes # Will set the id if it exists.
  end

  def dataset
    self.class.dataset
  end

  def id
    if @id
      @id
    else
      # If our model does not have an id, raise at the first occurence
      # of anyone expecting it. This prevents us from assigning associations
      # and other logical paths for things that do not exist in the db.
      raise MissingId
    end
  end

  def id=(id)
    @id = id
  end

  def attributes
    @attributes
  end

  # #attributes= is vulnerable to mass assignment attacks if used
  # directly with user input. Some sort of filter must be in place
  # before setting attributes or initializing a new model.
  def attributes=(attributes)
    @attributes = {}

    attributes.each do |key, value|
      writer = :"#{key}="

      if respond_to?(writer)
        send(writer, value)
      end
    end
  end

  # Strap in, the is probably the most complicated method
  # in the entire library.
  def ==(other)
    # If the classes don't match, they cannot possibly be equal.
    if self.class != other.class
      return false
    end

    # If the persisted state doesn't match, they also can never be equal.
    if persisted? != other.persisted?
      return false
    end

    # When persisted, check the other's id to see if it's the same,
    # cannot possible be equals if they have different ids.
    if persisted? && id != other.id
      return false
    end

    # Finally, compare the attributes hash. If all key/values match,
    # they are considered equal.
    attributes == other.attributes
  end

  def persisted?
    !!@id
  end

  # Use #save to write generic persistence code in things like form objects
  # so you don't have to reach inside the model to determine the proper
  # method to call.
  def save
    if persisted?
      update
    else
      create
    end
  end

  # #create (as well as #update, and #delete) return self on
  # success and nil on failure. This lets us use these actions
  # as if conditions which is convenience though dangerous.
  def create
    id = dataset.insert(attributes)

    if id
      self.id = id

      self
    else
      nil
    end
  end

  def update
    count = dataset.where(id: id).update(attributes)

    if count.to_i > 0
      self
    else
      nil
    end
  end

  def delete
    count = dataset.where(id: id).delete

    if count.to_i > 0
      self.id = nil

      self
    else
      nil
    end
  end
end
