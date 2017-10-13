desc 'open irb in gs context'
task :console do
  sh 'gs irb'
end

desc 'installs gems'
task :install do
  sh 'mkdir -p .gs & gs dep install'
end

desc 'tests the given [test].rb'
task :test, :name do |t, args|
  name = args[:name] || '*'

  sh "gs cutest -r ./test/#{name}.rb"
end
