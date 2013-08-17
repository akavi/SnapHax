Gem::Specification.new do |s|
  s.name        = 'snaphax'
  s.version     = '0.1.0'
  s.date        = '2013-07-16'
  s.summary     = "A library to interface with the SnapChat API"
  s.description = s.summary
  s.authors     = ["Arjun Kavi"]
  s.email       = 'arjun.kavi@gmail.com'
  s.files       = ["lib/snaphax.rb"]
  s.license     = 'MIT'
  s.add_dependency('httparty')
  s.add_dependency('ruby-mcrypt')
end
