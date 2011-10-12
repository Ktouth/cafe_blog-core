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

MigrationDirectory = File.expand_path('../../resource/migration', __FILE__)
shared_context 'Environment.setup' do
  let(:database_migration_params) { {} }
  let(:require_models) { true }
  before :all do
    clear_environment

    @database = Sequel.connect('amalgalite:///')
    require 'sequel/extensions/migration'
    Sequel::Migrator.run(@database, MigrationDirectory, database_migration_params)
    
    database_resetdata(@database)

    @environment = CafeBlog::Core::Environment.setup(:database => @database, :require => require_models)
  end
  after :all do
    @database.drop_tables(*@database.tables) rescue nil
  end
end
def database_demigrate(db, version = 0)
  require 'sequel/extensions/migration'
  Sequel::Migrator.run(db, MigrationDirectory, :target => version)
end
def database_resetdata(db, *excepts)
  db.transaction do
    ExampleDBDataTables.each do |t_name|
      next if excepts.include?(t_name)
      db[t_name].delete
      if ExampleDBSeqenceReset[t_name]
        db[:sqlite_sequence].filter(:name => t_name.to_s).update(:seq => 0)
      end
      db[t_name].insert_multiple(ExampleDBData[t_name])
    end
  end
end
