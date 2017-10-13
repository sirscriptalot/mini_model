# MiniModel

MiniModel is an alternative active record implementation to Sequel::Model.
It is designed to work with Sequel::Dataset, but aims to be a much smaller api
than Sequel::Model. The api is largely based on the lovely [Ohm][ohm] gem,
an ORM in Ruby for Redis.

## Installation

`$ gem install mini_model`

You must also install [Sequel][sequel] and the database of your choice.

## Usage

Checkout the tests and `./examples` for more advanced use cases,
but the basics look something like:

```ruby
  require 'mini_model'
  require 'sequel'
  require 'sqlite' # Or any Sequel supported database.

  DB = Sequel.sqlite

  class Model
    include MiniModel

    # ...
  end

  Model.dataset = DB[:models]
```

## API

### Class Methods

`::dataset=` Sets the dataset for the given model.

`::dataset` Gets the assigned dataset.

`::attribute` Macro for generating an accessor for the attributes hash.

`::build` Converts a dataset to an array of model instances.

`::create` Convenience for `new(attributes).create`.

`::[]` Fetches a record for the given id via Sequel::Datase#first.

`::first` Fetches the first record for the given args, see Sequel::Dataset#first.

`::all` Fetch all records for the current dataset, see Sequel::Dataset#all.

`::where` Fetch records for the given conditions, see Sequel::Dataset#where.

`::to_foreign_key` Contains the covention for converting class names into foreign keys.
`Person` becomes `person_id`.

`::children` Association macro for "1 to n". See the section on associations below.

`::child` Association macro for "1 to 1" where the foreign key is on the other table.

`::parent` Association macro for "1 to 1/n" where the foreign key is on our table.

### Instance Methods

`#initialize` Sets the given attributes on the model instance, note that if the id
is in the attributes hash it will also be assigned.

`#dataset` Delegates to the class' dataset.

`#id` The current id value, if it exists, or raises an error.
Raising the error is to stop anything right away that may depend on the id.
We don't want to be assigning nil all over our associations and what have you.

`#id=` Assigns the id.

`#attributes` Gets the attributes hash.

`#attributes=` For each key/value in the given hash, sends the writer (from key)
to self if the method exists.

`#==` Compares two models to see if they are equals. It ensures that the class,
id, and attributes of each are the same.

`#persisted?` Used to check if a model has an id or not. It is assumed if
it has an id it's in the database.

`#save` Delegates to the proper persistence method.

`#create` Inserts attributes in the database. Returns self on success, nil
on failure.

`#update` Updates attributes in the database for id. Returns self on success,
nil on failure.

`#delete` Deletes itself from the database and unassigns the id. If you want
to do anything with the id after deletion, copy it before calling delete.

## Attributes

Attributes in MiniModel are all stored internally inside the `@attributes` hash.
The `::attribute` macro is really just an easy way of defining accessors
similar to `attr_accessor`, but getting and setting on that hash.

There is plans to implement a more robust attribute api,
but right now it is not implemented.

## Associations

Associations in MiniModel are largely inspired by [Ohm][ohm].
They are pretty much the same, but where Ohm uses a collection/reference metaphor,
MiniModel uses parent/child(ren).

Note that associations finders are not cached at this time, a small caching
layer will be added in the future.

### Parent

Lets take a look at the `::parent` macro.

```ruby
class Photo
  include MiniModel

  # It turns this...

  parent :user, :User

  # Into something like this...

  def user_id
    @attributes[:user_id]
  end

  def user_id=(user_id)
    @attributes[:user_id] = user_id
  end

  def user
    User[user_id]
  end

  def user=(user)
    self.user_id = user.id
  end
end
```

This means that when we say `parent :user, :User` user is our parent, and the foreign
key is on our table. You can customize the foreign key by passing a third symbol argument,
but with this convention the primary key on the parent must be id. You can always
skip the parent macro and implement things manually if you're using a different
primary key.

### Children

Children are even simpler than parents, as it's just a finder.

```ruby
  class User
    include MiniModel

    children :photos, :Photo

    # Roughly becomes...

    def photos
      Photo.where(user_id: id)
    end
  end
```

Once again you can customize the foreign key (user_id) with a third argument,
but not that it's referring to the id on ourself. These macros are just
conveniences for the 90% use case, unique situations are easy to implement
yourself like...

```ruby
  def photos
    Photo.where(user_email: email)
  end
```

An **important** thing to note when dealing with associations is that MiniModel
only provides the association writer on the "child" side of the relationship. That
means the parent must be saved to start assign associations, but also you can't do
something like `user.photos << photo` and have it persist. Another note is the relationship
will not be persisted until calling save (or create/update) on the child.

On our User model, if we want to work from that side of the association, you could
create delegation methods like so:

```
  def add_photo(photo)
    photo.user_id = id
  end
```

### Child

The final association macro is `child`. It works the same exact way as
`children` though uses the `.first` finder to get a single record.

```ruby
  class User
    include MiniModel

    child :profile, :Profile

    # This roughly expands to...

    def profile
      Profile.first(user_id: id)
    end
  end
```

## Non-SQL Databases

MiniModel is designed to work with Sequel (and SQL Databases),
though it will work with anything that implements a subset of Sequel::DataSet.

If you would like your write your own adapter/dataset for a non SQL database,
MiniMapper depends on the following Sequel::DataSet methods:

`Sequel::Dataset#all`
`Sequel::Dataset#delete`
`Sequel::Dataset#first`
`Sequel::Dataset#insert`
`Sequel::Dataset#update`
`Sequel::Dataset#where`

[ohm]: http://github.com/soveran/ohm
[sequel]: https://github.com/jeremyevans/sequel

