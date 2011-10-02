$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cafe_blog-core'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

def clear_environment
  CafeBlog::Core::Environment.instance_variable_set(:@instance, nil)
  mmod = CafeBlog::Core::Model
  mmod.constants.each do |c|
    mmod.instance_eval { remove_const c } if mmod.const_get(c) < Sequel::Model
  end
  $LOADED_FEATURES.delete_if {|x| x =~ %r!cafe_blog/core/model/.*$! }
end