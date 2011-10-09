require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::Author' do
  include_context 'Environment.setup'
  shared_context 'authors reset' do
    before :all do
      database_resetdata(@database)
    end
  end
  def valid_args(args = {})
    codes = @database[:authors].map {|r| r[:code] }
    code = nil
    unless args[:code]
      i = 1
      loop do
        code = 'foobar_baz%02d' % i
        break unless codes.include?(code)
        i += 1
      end
    end
    {:id => nil, :code => code }.merge(args)
  end

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
      @admin = CafeBlog::Core::Model::Author[:id => 1]
    end
    specify '@admin is exist' do @admin.should_not be_nil end
    subject { @author }

    it { should respond_to(:id) }
    it { should respond_to(:code) }

    context '#id' do
      include_context 'authors reset'
      subject { @author.id }
      it { should be_nil }
      it { expect { @author.id = 15; @author[:code] = valid_args[:code]; @author.save }.to change { [@author.id, @author.new?] }.from([nil, true]).to([15, false]) }
      it { expect { CafeBlog::Core::Model::Author.set(valid_args(:id => nil)) }.to raise_error }
      it { expect { @new = CafeBlog::Core::Model::Author.insert(valid_args(:id => nil)) }.to change { @new }.from(nil).to(16) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:id => @admin.id)) }.to raise_error }
    end

    context '#code' do
      include_context 'authors reset'
      subject { @author.code }
      it { should be_nil }
      it { expect { @author.code = 'dummy_code'; @author.save }.to change { [@author.code, @author.new?] }.from([nil, true]).to(['dummy_code', false]) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:code => nil)) }.to raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:code => @admin.code)) }.to raise_error }
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
