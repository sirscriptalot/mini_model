require_relative "./lib/mini_model"

Gem::Specification.new do |s|
  s.name     = "mini_model"
  s.summary  = "MiniModel"
  s.version  = MiniModel::VERSION
  s.authors  = ["Steve Weiss"]
  s.email    = ["weissst@mail.gvsu.edu"]
  s.homepage = "https://github.com/sirscriptalot/mini_model"
  s.license  = "MIT"
  s.files    = `git ls-files`.split("\n")

  s.add_development_dependency "cutest", "~> 1.2"
  s.add_development_dependency "sequel", "~> 5.1"
  s.add_development_dependency "sqlite3", "~> 1.3"
end
