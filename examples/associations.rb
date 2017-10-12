class User
  include MiniModel

  attribute :email

  children :photos, :Photo

  children :photo_comments, :PhotoComment

  children :videos, :Video

  children :video_comments, :VideoComment

  def comments
    photo_comments + video_comments
  end
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

  def subject
    raise NotImplementedError, "#subject must be defined on subclasses of Comment"
  end
end

class PhotoComment < Comment
  parent :photo, :Photo

  def subject
    photo
  end
end

class VideoComment < Comment
  parent :video, :Video

  def subject
    video
  end
end
