require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::AuthorLog' do
  include_context 'Environment.setup'
  shared_context 'author_logs reset' do
    before :all do
      database_resetdata(@database)
    end
  end
  def valid_args(args = {})
    {:time => Time.local(2004, 4, 4, 13, 22, 18), :host => 'ppp09156.host.example.com', :action => 'login'}.merge(args)
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
    it { should_not include(:time=) }
    it { should_not include(:host=) }
    it { should_not include(:action=) }
  end

  describe 'instance methods' do
    before do
      @item = @model.new
      @exist_item = @model[1]
    end
    def args_set(*excepts)
      valid_args.tap {|args| excepts.each {|x| args.delete(x) } }.each do |key, value|
        begin
          @item.send("#{key}=", value)
        rescue
          @item.values[key] = value
        end
      end
    end
    specify '@exist_item is exist' do @exist_item.should_not be_nil end
    subject { @item }

    it { should respond_to(:id) }
    it { should respond_to(:time) }
    it { should_not respond_to(:time=) }
    it { should respond_to(:host) }
    it { should_not respond_to(:host=) }
    it { should respond_to(:author) }
    it { should respond_to(:author=) }
    it { should be_respond_to(:author_id) }
    it { expect { subject.author_id }.to raise_error(NoMethodError) }
    it { should be_respond_to(:author_id=) }
    it { expect { subject.author_id = 2 }.to raise_error(NoMethodError) }
    it { should respond_to(:action) }
    it { should respond_to(:action=) }
    
    context '#id' do
      include_context 'author_logs reset'
      before { args_set(:id) }
      subject { @item.id }

      it { should be_nil }
      it { expect { @item.id = 115; @item.save }.to change { [@item.id, @item.new?] }.from([nil, true]).to([115, false]) }
      it { expect { @model.create(valid_args(:id => nil)) }.to raise_error }
      it { expect { @new = @model.insert(valid_args(:id => nil)) }.to change { @new }.from(nil).to(116) }
      it { expect { @model.insert(valid_args(:id => @exist_item.id)) }.to raise_error }
      it { expect { @exist_item.id = 5932 }.to raise_error }
    end

    context '#time' do
      include_context 'author_logs reset'
      before do
        @time_last = @model.order_by(:id.desc).first.id
        @time_now = Time.now
        Time.should_receive(:now).with(no_args).and_return { @time_now }
        @item = @model.new; args_set(:time)
      end
      def _valid_args(time = nil)
        Time.should_receive(:now).with(no_args).and_return { @time_now }
        valid_args(:time => time)
      end
      subject { @item.time }

      it { should be_a(Time) }
      it { should == @time_now }
      it { expect { @item.time = Time.local(2001, 11, 25, 13, 22, 48) }.to raise_error(NoMethodError) }
      it { expect { @exist_item.time = 5932 }.to raise_error(NoMethodError) }
      it { expect { @model.create(_valid_args) }.to raise_error }
      it { expect { @time_last = @model.insert(valid_args(:time => Time.local(2008, 3, 7, 5, 19, 22))) }.to_not raise_error }
      it { expect { @time_last = @model.insert(valid_args(:time => @time_now)) }.to change { @time_last }.by(1) }
      it { expect { @item.values[:time] = nil; @item.save }.to raise_error(Sequel::ValidationFailed) }
    end

    context '#host' do
      include_context 'author_logs reset'
      before do
        @host_last = @model.order_by(:id.desc).first.id
        @host_addr = 'ppp123-45-67-89.tokyo-inc.jp'
        CafeBlog::Core::Environment.should_receive(:get_host_address).with(no_args).and_return { @host_addr }
        @item = @model.new; args_set(:host)
      end
      def _valid_args(host = nil)
        CafeBlog::Core::Environment.should_receive(:get_host_address).with(no_args).and_return { @host_addr }
        valid_args(:host => host)
      end
      subject { @item.host }

      it { should be_a(String) }
      it { should == @host_addr }
      it { expect { @item.host = 'host.localtime.org' }.to raise_error(NoMethodError) }
      it { expect { @exist_item.host = '5932' }.to raise_error(NoMethodError) }
      it { expect { @model.create(_valid_args) }.to raise_error }
      it { expect { @host_last = @model.insert(valid_args(:host => 'example.host.org')) }.to_not raise_error }
      it { expect { @host_last = @model.insert(valid_args(:host => @host_addr)) }.to change { @host_last }.by(1) }
      it { expect { @item.values[:host] = nil; @item.save }.to raise_error(Sequel::ValidationFailed) }
      it { expect { @item.values[:host] = 123456; @item.save }.to raise_error(TypeError) }
      it { expect { @item.values[:host] = /regexp/; @item.save }.to raise_error(TypeError) }
      it { expect { @item.values[:host] = :sample; @item.save }.to raise_error(TypeError) }
      it { expect { @item.values[:host] = 'invalid host address format'; @item.save }.to raise_error(Sequel::ValidationFailed) }
    end

    context '#author' do
      before :all do
        @author_class = CafeBlog::Core::Model::Author
        @_last_author_id = @author_class.order_by(:id.desc).first.id
      end
      after :all do
        @author_class.filter('id > ?', @_last_author_id).destroy
        reset_autoincrement_count(@database, :authors, @_last_author_id)
      end
      include_context 'author_logs reset'
      before do
        @author_last = @model.order_by(:id.desc).first.id
        @item = @model.new; args_set(:author)
        @admin, @example = @author_class[1], @author_class[3]
      end
      def _valid_args(author_id = nil); valid_args(:author_id => author_id).tap {|x| x.delete(:time); x.delete(:host) } end
      subject { @item.author }

      it { should be_nil }
      it { @exist_item.author.should be_a(@author_class) }
      it { expect { @item.author = @admin }.to change { @item.author }.to(@admin) }
      it { expect { @item.author = @admin; @item.save }.to_not raise_error }
      it { expect { @model.create(_valid_args(@admin.id)) }.to_not raise_error }
      it { expect { @model.create(_valid_args(nil)) }.to_not raise_error }
      it { expect { @author_last = @model.insert(valid_args(:author_id => nil)) }.to_not raise_error }
      it { expect { @author_last = @model.insert(valid_args(:author_id => nil)) }.to change { @author_last }.by(1) }
      it { expect { @author_last = @model.insert(valid_args(:author_id => @example.id)) }.to_not raise_error }
      it { expect { @author_last = @model.insert(valid_args(:author_id => @example.id)) }.to change { @author_last }.by(1) }
      it { expect { @item.author = nil; @item.save }.to_not raise_error }
      it { expect { @item.author = nil; @item.save }.to change { @item.id.nil? }.to(false) }
      it { expect { @item.author = 12354648 }.to raise_error }
      it { expect { @item.author = 'new_user001' }.to raise_error }
      it { expect { @item.author = @author_class.new(:code => 'new_user001', :name => '新規ユーザ') }.to raise_error(Sequel::Error) }
      it { expect { @exist_item.author = @example }.to raise_error(CafeBlog::Core::ModelOperationError) }

      context '(foreign key on delete)' do
        before do
          @dummy = @author_class.create(:code => 'new_user003', :name => 'テストユーザ')
          @dummy_id = @dummy.id
          @item.author = @dummy
          @item.save
        end
        after { @dummy.destroy rescue nil }
        it { expect { @dummy.destroy rescue nil; @item.reload }.to change { @item.author(true) }.to(nil) }
        it { expect { @dummy.destroy rescue nil; @item.reload }.to change { @item.instance_eval { author_id } }.to(nil) }
      end
    end

    context '#action' do
      include_context 'author_logs reset'
      before do
        @action_last = @model.order_by(:id.desc).first.id
        @item = @model.new; args_set(:action)
      end
      subject { @item.action }

      it { should nil }
      it { @exist_item.action.should be_a(String) }
      it { expect { @item.action = 'login' }.to_not raise_error }
      it { expect { @item.action = 'post.article' }.to_not raise_error }
      it { expect { @exist_item.action = '5932' }.to raise_error(CafeBlog::Core::ModelOperationError) }
      it { expect { @model.create(valid_args) }.to raise_error }
      it { expect { @action_last = @model.insert(valid_args(:action => 'post.comment')) }.to_not raise_error }
      it { expect { @action_last = @model.insert(valid_args(:action => 'change.password')) }.to change { @action_last }.by(1) }
      it { expect { @action_last = @model.insert(valid_args(:action => nil)) }.to raise_error(Sequel::Error) }
      it { expect { @item.action = nil; @item.save }.to raise_error(Sequel::InvalidValue) }
      it { expect { @item.action = ''; @item.save }.to raise_error(Sequel::ValidationFailed) }
      it { expect { @item.action = 123456; @item.save }.to raise_error(Sequel::ValidationFailed) }
      it { expect { @item.action = /regexp/; @item.save }.to raise_error(Sequel::ValidationFailed) }
      it { expect { @item.action = Time.now; @item.save }.to raise_error(Sequel::ValidationFailed) }
      it { expect { @item.action = 'invalid action format'; @item.save }.to raise_error(Sequel::ValidationFailed) }
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

