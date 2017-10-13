db = Sequel.sqlite

class User
  include MiniModel
end

User.dataset = db[:users]

class Post
  include MiniModel
end

Post.dataset = db[:posts]
