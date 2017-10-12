class Model
  include MiniModel

  attribute :deleted_at

  def deleted?
    !!deleted_at
  end

  def delete
    self.deleted_at = Time.now

    update
  end
end
