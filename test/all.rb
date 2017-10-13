require 'sequel'
require 'sqlite3'
require_relative '../lib/mini_model'

db = Sequel.sqlite

db.create_table :users do
  primary_key :id

  String :email, size: 255, unique: true, not_null: true
end

db.create_table :profiles do
  primary_key :id

  foreign_key :user_id, :users, on_delete: :cascade
end


db.create_table :photos do
  primary_key :id

  foreign_key :user_id, :users, on_delete: :cascade

  String :url, unique: true, not_null: true
end

db.create_table :videos do
  primary_key :id

  foreign_key :user_id, :users, on_delete: :cascade

  String :url, unique: true, not_null: true
end

db.create_table :photo_comments do
  primary_key :id

  foreign_key :user_id, :users, on_delete: :cascade

  foreign_key :photo_id, :photos, on_delete: :cascade

  # Make sure we can spam user comments to Twitter, we need attention.
  String :body, size: 140, nut_null: true
end

db.create_table :video_comments do
  primary_key :id

  foreign_key :user_id, :users, on_delete: :cascade

  foreign_key :video_id, :videos, on_delete: :cascade

  # Make sure we can spam user comments to Twitter, we need attention.
  String :body, size: 140, nut_null: true
end

require_relative '../examples/associations'

User.dataset = db[:users]

Photo.dataset = db[:photos]

Video.dataset = db[:videos]

PhotoComment.dataset = db[:photo_comments]

VideoComment.dataset = db[:video_comments]

prepare do
  # Ensure each test runs with a clean database.
  [User, Photo, Video, PhotoComment, VideoComment].each do |model|
    model.dataset.delete
  end
end

test '::dataset= sets dataset' do
  original = User.dataset

  User.dataset = :fake

  assert_equal User.dataset, :fake

  User.dataset = original
end

test '::dataset gets dataset' do
  assert_equal User.dataset, db[:users]
end

test '::attribute defines accessor methods' do
  user = User.new

  assert user.respond_to?(:email)
  assert user.respond_to?(:email=)
end

test '::build returns an instance when given a hash' do
  user = User.build({})

  assert user.is_a?(User)
end

test '::build returns nil when given a falsey value' do
  user = User.build(false)

  assert user.nil?
end

test '::create creates an instance and persists it in the database' do
  user = User.create(email: 'name@example.com')

  assert user.is_a?(User)
  assert user.persisted?
end

test '::[] fetchs record for a given id' do
  left = User.create(email: 'name@example.com')

  right = User[left.id]

  assert_equal left, right
end

test '::first fetchs one record for for the give conditions' do
  email = 'name@example.com'

  user = User.create(email: email)

  assert_equal User.first(email: email), user
end

test '::all fetchs all records in the dataset' do
  one = User.create(email: 'one@example.com')

  two = User.create(email: 'two@example.com')

  all = User.all

  assert all.include?(one)
  assert all.include?(two)
end

test '::where fetch all records in the dataset matching condition' do
  email = 'one@example.com'

  one = User.create(email: email)

  two = User.create(email: 'two@example.com')

  assert User.where(email: email).include?(one)
end

test '::to_foreign_key snake cases and appends _id to model name' do
  assert_equal User.to_foreign_key, :user_id
  assert_equal PhotoComment.to_foreign_key, :photo_comment_id
end

test '::children defines getter' do
  user = User.new

  assert user.respond_to?(:photos)
  assert user.respond_to?(:photo_comments)
end

test '::child defines getter' do
  user = User.new

  assert user.respond_to?(:profile)
end

test '::parent defines getters and setters' do
  profile = Profile.new

  assert profile.respond_to?(:user)
  assert profile.respond_to?(:user=)
  assert profile.respond_to?(:user_id)
  assert profile.respond_to?(:user_id=)
end

test '#dataset is delegates to class' do
  user = User.new

  assert_equal user.dataset, User.dataset
end

test '#id returns id when it exists' do
  id = 1

  user = User.new(id: id)

  assert_equal user.id, id
end

test '#id raises when missing an id' do
  user = User.new

  assert_raise MiniModel::MissingId do
    user.id
  end
end

test '#id= sets the id' do
  id = 2

  user = User.new

  user.id = id

  assert_equal user.id, id
end

test '#attributes returns a hash' do
  user = User.new

  assert user.attributes.is_a?(Hash)
end

test '#attributes= sets key/value in attributes hash that exist' do
  id = 1

  email = 'name@example.com'

  user = User.new

  user.attributes = { id: id, email: email }

  assert_equal user.id, id
  assert_equal user.email, email
  assert_equal user.email, user.attributes[:email]
end

test '#attributes= resets all attributes, but not id' do
  id = 1

  email = 'name@example.com'

  user = User.new

  user.attributes = { id: id, email: email }

  assert_equal user.id, id
  assert_equal user.email, email
  assert_equal user.email, user.attributes[:email]

  user.attributes = {}

  assert_equal user.id, id
  assert_equal user.email, nil
  assert_equal user.email, user.attributes[:email]
end

test '#attributes= raises when there is no accessor for a key' do
  user = User.new

  assert_raise do
    user.attributes = { foo: :bar }
  end
end

setup do
  one = User.new(id: 1, email: 'one')
  two = User.new(id: 1, email: 'one')

  [one, two]
end

test '#== must have class the same' do |one, two|
  assert_equal one.class, two.class
  assert_equal one, two
end

test '#== must have id the same' do |one, two|
  assert_equal one.id, two.id
  assert_equal one, two

  two.id = 2

  assert one != two
end

test '#== must have attributes the same' do |one, two|
  assert_equal one.attributes, two.attributes
  assert_equal one, two

  two.attributes = { email: 'two' }

  assert one != two
end

test '#persisted? checks if the model has an id or not' do
  user = User.new

  assert !user.persisted?

  user.id = 1

  assert user.persisted?
end

test '#save delegates to the proper persistence method' do
  klass = Class.new(User) do
    def created?
      @did_create
    end

    def create
      @did_create = true
    end

    def updated?
      @did_update
    end

    def update
      @did_update = true
    end
  end

  to_create = klass.new

  to_create.save

  assert to_create.created? && !to_create.updated?

  to_update = klass.new

  to_update.id = 1

  to_update.save

  assert !to_update.created? && to_update.updated?
end

class SuccessDataset
  def insert(*args)
    9
  end

  def where(*args)
    self
  end

  def update(*args)
    1
  end

  def delete(*args)
    1
  end
end

class FailureDataset
  def insert(*args)
    nil
  end

  def where(*args)
    self
  end

  def update(*args)
    0
  end

  def delete(*args)
    0
  end
end

setup do
  klass = Class.new(User)

  klass.dataset = SuccessDataset.new

  klass.new
end

test '#create assigns id on success' do |instance|
  instance.create

  assert instance.id
end

test '#create returns self on success' do |instance|
  ret = instance.create

  assert_equal ret, instance
end

setup do
  klass = Class.new(User)

  klass.dataset = FailureDataset.new

  klass.new
end

test '#create returns nil on failure' do |instance|
  ret = instance.create

  assert ret.nil?
end

setup do
  klass = Class.new(User)

  klass.dataset = SuccessDataset.new

  klass.new(id: 1)
end

test '#update returns self on success' do |instance|
  ret = instance.update

  assert_equal ret, instance
end

setup do
  klass = Class.new(User)

  klass.dataset = FailureDataset.new

  klass.new(id: 1)
end

test '#update returns nil on failure' do |instance|
  ret = instance.update

  assert ret.nil?
end

setup do
  klass = Class.new(User)

  klass.dataset = SuccessDataset.new

  klass.new(id: 1)
end

test '#delete unassigns id on success' do |instance|
  assert instance.persisted?

  instance.delete

  assert !instance.persisted?
end

test '#delete returns self on success' do |instance|
  ret = instance.delete

  assert_equal ret, instance
end

setup do
  klass = Class.new(User)

  klass.dataset = FailureDataset.new

  klass.new(id: 1)
end

test '#delete returns nil on failure' do |instance|
  ret = instance.delete

  assert ret.nil?
end
