Gem::Specification.new do |s|
  s.name        = 'mongo_data_puller'
  s.version     = '0.0.0'
  s.date        = '2014-11-24'
  s.summary     = "Sinks data from Sql to mongo"
  s.description = "Sinks data from Sql to mongo"
  s.authors     = ["Paritosh Singh"]
  s.email       = 'i@paritoshsingh.com'
  s.files       = ["lib/mongo_data_puller.rb"]
  s.homepage    = ''

  s.add_dependency 'mongo_mapper'

  s.license     = 'MIT'
end