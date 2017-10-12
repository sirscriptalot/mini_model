DB = Sequel.sqlite

class User
  include MiniModel
end

User.dataset = DB[:users]

class Post
  include MiniModel
end

Post.dataset = DB[:posts]
