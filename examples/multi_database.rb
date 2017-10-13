db1 = Sequel.sqlite

db2 = Sequel.sqlite # sorry ibm

class User
  include MiniModel
end

User.dataset = db1[:users]

class Post
  include MiniModel
end

Post.dataset = db2[:posts]
