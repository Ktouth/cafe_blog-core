require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::Tag' do
  include_context 'Environment.setup'
  before :all do
    @model = CafeBlog::Core::Model::Tag
  end
  shared_context 'tags reset' do
    before :all do
      database_resetdata(@database)
    end
  end
  def valid_args(args = {})
    {}.merge(args)
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

  context '.setter_methods' do
    subject { @model.setter_methods }
    it { should_not include(:id=) }
  end

  describe 'instance methods' do
    before do
      @tag = @model.new
      @first, @second, @third = @model[1], @model[9], @model[13]
    end
    def args_set(*excepts)
      valid_args.tap {|args| excepts.each {|x| args.delete(x) } }.each do |key, value|
        @tag.send("#{key}=", value)
      end
    end
    specify '@first is exist' do @first.should_not be_nil end
    subject { @tag }

    it { should respond_to(:id) }

    context '#id' do
      include_context 'tags reset'
      before { args_set(:id) }
      subject { @tag.id }

      it { should be_nil }
      it { expect { @tag.id = 30; @tag.save }.to change { [@tag.id, @tag.new?] }.from([nil, true]).to([30, false]) }
      it { expect { @new = @model.insert(valid_args) }.to change { @new }.from(nil).to(31) }
      it { expect { @model.insert(valid_args(:id => @first.id)) }.to raise_error }
      it { expect { @model.create(valid_args) }.to_not raise_error }
      it { expect { @first.id = 5932 }.to raise_error }
    end
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
