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
    name = nil
    unless args[:name]
      names = @database[:tags].map {|r| r[:name] }
      i = 1
      loop do
        name = 'タグ名%02d' % i
        break unless names.include?(name)
        i += 1
      end
    end
    {:name => name}.merge(args)
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
      @first, @second, @third = @model[1], @model[9], @model[12]
    end
    def args_set(*excepts)
      valid_args.tap {|args| excepts.each {|x| args.delete(x) } }.each do |key, value|
        @tag.send("#{key}=", value)
      end
    end
    specify '@first is exist' do @first.should_not be_nil end
    subject { @tag }

    it { should respond_to(:id) }
    it { should respond_to(:name) }
    it { should respond_to(:code) }
    it { should be_respond_to(:group) }
    it { should be_respond_to(:group_id) }
    it { expect { subject.group_id }.to raise_error(NoMethodError) }
    it { should be_respond_to(:group_id=) }
    it { expect { subject.group_id = 2 }.to raise_error(NoMethodError) }

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

    context '#name' do
      include_context 'tags reset'
      before { args_set(:name) }
      subject { @tag.name }

      it { should be_nil }
      it { expect { @tag.name = 'dummy_code'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['dummy_code', false]) }
      it { expect { @tag.name = 'foobar128123'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['foobar128123', false]) }
      it { expect { @tag.name = '123564896123'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['123564896123', false]) }
      it { expect { @tag.name = 'asadf456asdfa456adf7a89adsf123'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['asadf456asdfa456adf7a89adsf123', false]) }
      it { expect { @tag.name = 'asa'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['asa', false]) }
      it { expect { @tag.name = '123456789'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['123456789', false]) }
      it { expect { @tag.name = '日本語'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['日本語', false]) }
      it { expect { @tag.name = 'BADtest123'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['BADtest123', false]) }
      it { expect { @tag.name = '__test__'; @tag.save }.to change { [@tag.name, @tag.new?] }.from([nil, true]).to(['__test__', false]) }
      it { expect { @model.insert(valid_args(:name => nil)) }.to raise_error }
      it { expect { @model.insert(valid_args(:name => @first.name)) }.to raise_error }
      it { expect { @tag.name = ''; @tag.save }.to raise_error }
      it { expect { @tag.name = 'ab'; @tag.save }.to_not raise_error }
      it { expect { @tag.name = '短い'; @tag.save }.to_not raise_error }
    end

    context '#code' do
      include_context 'tags reset'
      before { args_set(:code) }
      subject { @tag.code }

      it { should be_nil }
      it { expect { @tag.code = 'dummy_code'; @tag.save }.to change { [@tag.code, @tag.new?] }.from([nil, true]).to(['dummy_code', false]) }
      it { expect { @tag.code = 'foobar128123'; @tag.save }.to change { [@tag.code, @tag.new?] }.from([nil, true]).to(['foobar128123', false]) }
      it { expect { @tag.code = 'asadfdefg'; @tag.save }.to change { [@tag.code, @tag.new?] }.from([nil, true]).to(['asadfdefg', false]) }
      it { expect { @model.insert(valid_args(:code => nil)) }.to_not raise_error }
      it { expect { @model.insert(valid_args(:code => @first.code)) }.to raise_error }
      it { expect { @model.create(valid_args(:code => 'valid4create')) }.to_not raise_error }
      it { expect { @new = @model.create(valid_args(:code => 'valid4create2')) }.to change { @new } }
      it { expect { @tag.code = nil; @tag.save }.to_not raise_error }
      it { expect { @tag.code = ''; @tag.save }.to raise_error }
      it { expect { @tag.code = '123564896123'; @tag.save }.to raise_error }
      it { expect { @tag.code = 'ab'; @tag.save }.to raise_error }
      it { expect { @tag.code = 'asadf456asdfa456adf7a89adsf123'; @tag.save }.to raise_error }
      it { expect { @tag.code = '123456789'; @tag.save }.to raise_error }
      it { expect { @tag.code = '日本語'; @tag.save }.to raise_error }
      it { expect { @tag.code = 'BADtest123'; @tag.save }.to raise_error }
      it { expect { @tag.code = '__test__'; @tag.save }.to raise_error }
      it { expect { @first.code = 'alter_first'; @first.save }.to change { [@first.code, @first.new?] }.from(['no_group', false]).to(['alter_first', false]) }
    end

    context '#to_code' do
      include_context 'tags reset'
      before :all do
        @all_to_code = ExampleDBData[:tags].sort {|a, b| a[:id] <=> b[:id] }.map {|x| x[:code] || ('tag%04d' % x[:id]) }
        @tag_code = 'tag%04d' % (@model.max(:id) + 1)
      end
      before { args_set }
      it { @model.order_by(:id).map {|x| x.to_code }.should == @all_to_code }
      it { @tag.to_code.should == 'tag0000' }
      it { expect { @tag.code = 'alter_first' }.to change { @tag.to_code }.from('tag0000').to('alter_first') }
      it { expect { @tag.save; @tag_code = 'tag%04d' % @tag.id }.to change { @tag.to_code }.from('tag0000').to(@tag_code) }
      it { expect { @tag.code = 'alter_first'; @tag.save }.to change { [@tag.new?, @tag.to_code] }.from([true, 'tag0000']).to([false, 'alter_first']) }
    end

    context '#group' do
      before :all do
        @_last_group_id = @model.order_by(:id.desc).first.id
      end
      after :all do
        @model.filter('id > ?', @_last_group_id).destroy
        reset_autoincrement_count(@database, :tags, @_last_group_id)
      end
      include_context 'tags reset'
      before do
        @tag_last = @model.order_by(:id.desc).first.id
        args_set(:group)
      end
      def _valid_args(group_id = nil); valid_args(:group_id => group_id) end
      subject { @tag.group }

      it { should be_nil }
      it { @second.group.should be_a(@model) }
      it { expect { @tag.group = @first }.to change { @tag.group }.to(@first) }
      it { expect { @tag.group = @first; @tag.save }.to_not raise_error }
      it { expect { @model.create(_valid_args(@first.id)) }.to_not raise_error }
      it { expect { @model.create(_valid_args(nil)) }.to_not raise_error }
      it { expect { @tag_last = @model.insert(valid_args(:group_id => nil)) }.to_not raise_error }
      it { expect { @tag_last = @model.insert(valid_args(:group_id => nil)) }.to change { @tag_last }.by(1) }
      it { expect { @tag_last = @model.insert(valid_args(:group_id => @third.id)) }.to_not raise_error }
      it { expect { @tag_last = @model.insert(valid_args(:group_id => @third.id)) }.to change { @tag_last }.by(1) }
      it { expect { @tag.group = nil; @tag.save }.to_not raise_error }
      it { expect { @tag.group = nil; @tag.save }.to change { @tag.id.nil? }.to(false) }
      it { expect { @tag.group = 12354648 }.to raise_error }
      it { expect { @tag.group = 'new_user001' }.to raise_error }
      it { expect { @tag.group = @model.new(:code => 'new_tag001', :name => '新規タグタグ') }.to raise_error(Sequel::Error) }
      it { expect { @second.group = @third; @second.save }.to_not raise_error }
      it { expect { @second.group = @first }.to change { @second.group }.to(@first) }

      context '(foreign key on delete)' do
        before do
          @dummy = @model.create(:code => 'new_tag003', :name => 'テストタグタグタグ')
          @dummy_id = @dummy.id
          @tag.group = @dummy
          @tag.save
        end
        after { @dummy.destroy rescue nil }
        it { expect { @dummy.destroy }.to_not raise_error }
        it { expect { @dummy.destroy rescue nil }.to_not change { @tag.exists? } }
        it { expect { @dummy.destroy rescue nil; @tag.reload }.to change { @tag.group(true) }.to(nil) }
        it { expect { @dummy.destroy rescue nil; @tag.reload }.to change { @tag.instance_eval { group_id } }.to(nil) }
      end
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
