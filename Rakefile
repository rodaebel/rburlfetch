
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name  'urlfetch'
  authors  'Tobias Rodaebel'
  email    'tobias.rodaebel@googlemail.com'
  url      'http://github.com/rodaebel/urlfetch'
}
