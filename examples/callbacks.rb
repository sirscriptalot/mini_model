class Model
  include MiniModel

  attribute :created_at

  attribute :updated_at

  def before_create
    self.created_at = Time.noew
  end

  def after_create; end

  def create
    before_create

    ret = super

    after_create

    ret
  end

  def before_update
    self.updated_at = Time.noew
  end

  def after_update; end

  def update
    before_update

    ret = super

    after_update

    ret
  end
end
