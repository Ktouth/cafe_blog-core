require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::Author' do
  include_context 'Environment.setup'

  subject { CafeBlog::Core::Model::Author }
  it { should be_instance_of(Class) }
  it { should < Sequel::Model }
  context '.simple_table' do
    subject { CafeBlog::Core::Model::Author.simple_table }
    it { should == @database.literal(:authors) }
  end
  context '.primary_key' do
    subject { CafeBlog::Core::Model::Author.primary_key }
    it { should == :id }
  end
  context '.restrict_primary_key?' do
    subject { CafeBlog::Core::Model::Author.restrict_primary_key? }
    it { should be_true }
  end

  context '.setter_methods' do
    subject { CafeBlog::Core::Model::Author.setter_methods }
    it { should_not include(:id=) }
  end

  describe 'instance methods' do
    before do
      @author = CafeBlog::Core::Model::Author.new
    end
    subject { @author }

    it { should respond_to(:id) }

    context '#id(default)' do
      subject { @author.id }
      it { should be_nil }
    end
  end
end

describe 'migration: 001_create_authors' do
  let(:database_migration_params) { {:target => 1} }
  context 'migration.up' do
    include_context 'Environment.setup'
    specify 'version is 1' do @database[:schema_info].first[:version].should == 1 end
    specify 'created authors' do @database.tables.should be_include(:authors) end
  end
  context 'migration.down' do
    include_context 'Environment.setup'
    before :all do database_demigrate(@database, 0) end

    specify 'dropped authors' do @database.tables.should_not be_include(:authors) end
  end
end
