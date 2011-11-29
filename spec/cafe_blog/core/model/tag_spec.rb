require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::Tag' do
  include_context 'Environment.setup'
  before :all do
    @model = CafeBlog::Core::Model::Tag
  end
  shared_context 'Tags reset' do
    before :all do
      database_resetdata(@database)
    end
  end

  subject { @model }
  it { should be_instance_of(Class) }
  it { should < Sequel::Model }
  context '.simple_table' do
    subject { @model.simple_table }
    it { should == @database.literal(:tags) }
  end
  context '.primary_key' do
    subject { @model.primary_key }
    it { should == :id }
  end
  context '.restrict_primary_key?' do
    subject { @model.restrict_primary_key? }
    it { should be_true }
  end
end

describe 'migration: 004_create_tags' do
  context 'migration.up' do
    include_context 'Environment.setup'
    let(:database_migration_params) { {:target => 4} }
    let(:require_models) { false }
    specify 'version is 1' do @database[:schema_info].first[:version].should == 4 end
    specify 'created Tags' do @database.tables.should be_include(:tags) end
  end
  context 'migration.down' do
    include_context 'Environment.setup'
    let(:require_models) { false }
    before :all do database_demigrate(@database, 0) end

    specify 'dropped Tags' do @database.tables.should_not be_include(:tags) end
  end
end
