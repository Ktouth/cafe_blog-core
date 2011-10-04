$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cafe_blog-core'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

LibDirBase = File.expand_path('../../lib', __FILE__)
def clear_environment
  CafeBlog::Core::Environment.instance_variable_set(:@instance, nil)
  mmod = CafeBlog::Core::Model
  mmod.constants.each do |c|
    mmod.instance_eval { remove_const c } if mmod.const_get(c) < Sequel::Model
  end
  $LOADED_FEATURES.delete_if {|x| x =~ %r!cafe_blog/core/model/.*$! }
end

MigrationDirectory = File.expand_path('../../bin/migration', __FILE__)
shared_context 'Environment.setup' do
  before :all do
    clear_environment

    @database = Sequel.connect('sqlite:///')
    require 'sequel/extensions/migration'
    Sequel::Migrator.run(@database, MigrationDirectory)

    @environment = CafeBlog::Core::Environment.setup(:database => @database)
  end
  after :all do
    @database.drop_tables(*@database.tables) rescue nil
  end
end
