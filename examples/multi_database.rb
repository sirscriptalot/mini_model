DB1 = Sequel.sqlite

DB2 = Sequel.sqlite # sorry ibm

class User
  include MiniModel
end

User.dataset = DB1[:users]

class Post
  include MiniModel
end

Post.dataset = DB2[:posts]
