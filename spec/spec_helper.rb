$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rack/acceptable'
require 'spec'
require 'spec/autorun'
require 'pp'

Spec::Runner.configure do |config|
  
end
