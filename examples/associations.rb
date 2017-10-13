class User
  include MiniModel

  attribute :email

  child :profile, :Profile

  children :photos, :Photo

  children :photo_comments, :PhotoComment

  children :videos, :Video

  children :video_comments, :VideoComment

  def comments
    photo_comments + video_comments
  end
end

class Profile
  include MiniModel

  parent :user, :User
end

class Photo
  include MiniModel

  attribute :url

  parent :user, :User

  children :comments, :PhotoComment
end

class Video
  include MiniModel

  attribute :url

  parent :user, :User

  children :comments, :VideoComment
end

class Comment
  include MiniModel

  attribute :body

  parent :user, :User
end

class PhotoComment < Comment
  parent :photo, :Photo
end

class VideoComment < Comment
  parent :video, :Video
end
