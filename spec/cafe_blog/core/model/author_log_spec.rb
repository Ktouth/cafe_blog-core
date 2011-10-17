require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::AuthorLog' do
  include_context 'Environment.setup'
  shared_context 'author_logs reset' do
    before :all do
      database_resetdata(@database)
    end
  end
  def valid_args(args = {})
    {:id => nil,}.merge(args)
  end

  before :all do @model = CafeBlog::Core::Model::AuthorLog end

  subject { @model }
  it { should be_instance_of(Class) }
  it { should < Sequel::Model }

  context '.simple_table' do
    subject { @model.simple_table }
    it { should == @database.literal(:author_logs) }
  end
  context '.primary_key' do
    subject { @model.primary_key }
    it { should == :id }
  end
  context '.restrict_primary_key?' do
    subject { @model.restrict_primary_key? }
    it { should be_true }
  end
  context '.setter_methods' do
    subject { @model.setter_methods }
    it { should_not include(:id=) }
  end

  describe 'instance methods' do
    before do
      @item = @model.new
      @exist_item = @model[1]
    end
    def args_set(*excepts)
      valid_args.tap {|args| excepts.each {|x| args.delete(x) } }.each do |key, value|
        @item.send("#{key}=", value)
      end
    end
    specify '@exist_item is exist' do @exist_item.should_not be_nil end
    subject { @item }

    it { should respond_to(:id) }

    context '#id' do
      include_context 'author_logs reset'
      before { args_set(:id) }
      subject { @item.id }

      it { should be_nil }
      it { expect { @item.id = 115; @item.save }.to change { [@item.id, @item.new?] }.from([nil, true]).to([115, false]) }
      it { expect { @model.set(valid_args(:id => nil)) }.to raise_error }
      it { expect { @new = @model.insert(valid_args(:id => nil)) }.to change { @new }.from(nil).to(116) }
      it { expect { @model.insert(valid_args(:id => @exist_item.id)) }.to raise_error }
      it { expect { @exist_item.id = 5932 }.to raise_error }
    end
  end
end

describe 'migration: 002_create_author_logs' do
  context 'migration.up' do
    include_context 'Environment.setup'
    let(:database_migration_params) { {:target => 2} }
    let(:require_models) { false }
    specify 'version is 2' do @database[:schema_info].first[:version].should == 2 end
    specify 'created author_logs' do @database.tables.should be_include(:author_logs) end
  end
  context 'migration.down' do
    include_context 'Environment.setup'
    let(:require_models) { false }
    before :all do database_demigrate(@database, 0) end

    specify 'dropped authors' do @database.tables.should_not be_include(:author_logs) end
  end
end

