require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'CafeBlog::Core::Configuration' do
  subject { CafeBlog::Core::Configuration }
  it { should be_a(Class) }
end

describe 'database table: configurations' do
  include_context 'Environment.setup'
  let(:require_models) { false }

  before :all do
    @valid_key = 'example'
    @valid_values = {:foo => true, :bar => 'test', :baz => {:sample => [:foo, :bar, :baz]} }
    @rvalid_values = Marshal.dump(@valid_values)
    @dataset = @database[:configurations]
    @valid_key2 = 'foobarbaz'
  end

  context ':key' do
    it { expect { @dataset.insert(:key => nil, :values => @rvalid_values ) }.to raise_error }
    it { expect { @dataset.insert(:key => /nil/, :values => @rvalid_values ) }.to raise_error }
    it { expect { @dataset.insert(:key => Class, :values => @rvalid_values ) }.to raise_error }
    it { expect { @dataset.insert(:key => @dataset.first[:key], :values => @rvalid_values ) }.to raise_error }
  end  

  context ':values' do
    it { expect { @dataset.insert(:key => @valid_key2, :values => nil ) }.to raise_error }
    it { expect { @dataset.insert(:key => @valid_key2, :values => /^foo|bar$/ ) }.to raise_error }
    it { expect { @dataset.insert(:key => @valid_key2, :values => Module ) }.to raise_error }
  end
end

module TempNamespace; end

describe 'CafeBlog::Core.Configuration' do
  include_context 'Environment.setup'
  let(:require_models) { false }
  shared_context 'configurations reset' do
    before { database_resetdata(@database) }
    after :all do
      database_resetdata(@database)
    end
  end
  before :all do
    @valid_key = 'example'
    @valid_values = {:foo => true, :bar => 'test', :baz => proc { Hash.new } }
  end
  def _reset_config(klass); klass.instance_variable_set(:@__instance__, nil) end
  def _conv_values(base)
    base.inject({}) do |r, (k, v)|
      r[k] = v.is_a?(Proc) ? v.call : v
      r
    end
  end

  subject { CafeBlog::Core }
  it { should respond_to(:Configuration) }

  it { expect { subject.Configuration }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key, @valid_values, 1235651) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key, @valid_values) }.to_not raise_error(ArgumentError) }  
  it { expect { subject.Configuration(156489123, @valid_values) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(/regexp/, @valid_values) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(:symbol, @valid_values) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(Class, @valid_values) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration('Class', @valid_values) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration('112345691235', @valid_values) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key, /1123156/) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key, -1535.51) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key, Time.now) }.to raise_error(ArgumentError) }  
  it { expect { subject.Configuration(@valid_key, Module) }.to raise_error(ArgumentError) }  

  describe 'return value' do
    subject { CafeBlog::Core::Configuration(@valid_key, @valid_values) }
    it { should be_a(Class) }
    it { should < CafeBlog::Core::Configuration }
    it { should respond_to(:key) }
    it { subject.key.should == @valid_key }
  end

  describe 'singleton class' do
    before :all do
      @class = CafeBlog::Core::Configuration(@valid_key, @valid_values)
    end
    subject { @class }
    it { should_not respond_to(:new) }
    it { should respond_to(:instance) }
    it { @class.instance.should == @class.instance }
  end

  describe 'class methods' do
    context '(.load_values)' do
      include_context 'configurations reset'
      before do
        @class = CafeBlog::Core::Configuration(@valid_key, @valid_values)
        @result = nil
      end
      subject { @class }
      it { should_not respond_to(:load_values) }
      it { should be_respond_to(:load_values, true) }

      def _call; @class.send :load_values end

      context 'valid' do
        it { expect { @result = _call }.to change { @result }.to(ExampleDBConfigurationData[@valid_key]) }
      end
      context 'no record' do
        before { @database.stub_chain(:[], :filter, :first => nil) }
        it { expect { @result = _call }.to change { @result }.to(_conv_values(@valid_values)) }
      end
      context 'included invalid keys' do
        before do
          @values = Marshal.dump(ExampleDBConfigurationData[@valid_key].merge(:invalid => 'this value is invalid', :test => false)) 
          @database.stub_chain(:[], :filter, :first => {:key => @valid_key, :values => @values})
        end
        it { expect { @result = _call }.to change { @result }.to(ExampleDBConfigurationData[@valid_key]) }
      end
      context 'not found any valid keys' do
        before do
          @values = ExampleDBConfigurationData[@valid_key].dup
          @values.delete(:bar)
          @values.delete(:baz)
          @database.stub_chain(:[], :filter, :first => {:key => @valid_key, :values => Marshal.dump(@values)})
          @rvalues = @values.merge(:bar => @valid_values[:bar], :baz => @valid_values[:baz])
        end
        it { expect { @result = _call }.to change { @result }.to(_conv_values(@rvalues)) }
      end
      context 'not open environment' do
        before :all do clear_environment end
        after :all do @environment = CafeBlog::Core::Environment.setup(:database => @database, :require => false) end
        it { expect { @result = _call }.to raise_error(CafeBlog::Core::ApplicationError) }
      end
    end

    context '(.store_values)' do
      include_context 'configurations reset'
      before do
        @class = CafeBlog::Core::Configuration(@valid_key, @valid_values)
        @result = nil
        @dataset = @database[:configurations].filter(:key => @valid_key)
        @stored_values = ExampleDBConfigurationData[@valid_key].dup
        @stored_values[:baz] = [:Test, :Value, :Stored]
        @stored_values[:bar] = 'store check'
      end
      subject { @class }
      it { should_not respond_to(:store_values) }
      it { should be_respond_to(:store_values, true) }

      def _call
        @class.instance.baz = [:Test, :Value, :Stored]
        @class.instance.bar = 'store check'
        @class.send :store_values
      end
      def _values; (r = @dataset.first) ? Marshal.load(r[:values]) : nil end

      context 'valid' do
        it { expect { _call }.to change { _values }.to(@stored_values) }
      end
      context 'no record' do
        before do
          @stored_values = @valid_values.dup
          @stored_values[:baz] = [:Test, :Value, :Stored]
          @stored_values[:bar] = 'store check'

          @database.stub_chain(:[], :filter, :first => nil)
          @class.instance

          tmp = @database[:configurations].filter(:key => @valid_key)
          @database.stub_chain(:[], :filter => tmp)
          tmp.should_receive(:empty?).and_return { true }
          @database.stub_chain(:[], :insert).with(an_instance_of(Hash)) do |hash|
            hash[:key].should == @valid_key
            begin
              @dataset.insert(hash)
            rescue
              @dataset.filter(:key => @valid_key).update(:values => hash[:values])
            end
          end
        end
        it { expect { _call }.to change { _values }.to(@stored_values) }
      end
      context 'included invalid keys' do
        before do
          @class.instance.instance_variable_get(:@values)[:invalid] = 'this is invalid value'
        end
        it { expect { _call }.to change { _values }.to(@stored_values) }
      end
      context 'not found any valid keys' do
        before do
          h = @class.instance.instance_variable_get(:@values)
          h.delete(:foo)
          @stored_values[:foo] = @valid_values[:foo]
        end
        it { expect { _call }.to change { _values }.to(@stored_values) }
      end
      context 'not open environment' do
        before :all do clear_environment end
        after :all do @environment = CafeBlog::Core::Environment.setup(:database => @database, :require => false) end
        it { expect { _call }.to raise_error(CafeBlog::Core::ApplicationError) }
      end
    end

    context '.instance' do
      before { @class = CafeBlog::Core::Configuration(@valid_key, @valid_values) }
      it { expect {;}.to_not change { @class.instance } }
      it { @class.instance.should be_a(@class) }
      context 'load database' do
        before do
          @values = @class.send :load_values
          @class.should_receive(:load_values).with(no_args).and_return { @values }
        end
        it { expect { @values = @class.instance.instance_variable_get(:@values) }.to_not change { @values } }
      end
    end
  end

  describe 'instance methods' do
    before :all do
      @class = TempNamespace.const_set('ExampleConfig', CafeBlog::Core::Configuration('valid_key', @valid_values))
    end
    after :all do
      TempNamespace.module_eval { remove_const('ExampleConfig') }
    end
    subject { @class.instance }

    describe 'getter and setter methods' do
      it { @valid_values.keys.all? {|x| subject.respond_to? x }.should be_true }
      it { @valid_values.keys.all? {|x| subject.respond_to?("#{x}=") }.should be_true }
      it { @valid_values.all? {|k, v| subject.send(k) == (v.is_a?(Proc) ? v.call : v) }.should be_true }
    end

    describe '#inspect' do
      before { @class.instance.instance_variable_set(:@foobarbaz, '123456789') }
      subject { @class.instance.inspect }
      it { should == '#<%s @values=%s>' % [@class.name, @class.instance.instance_variable_get(:@values).inspect]}      
    end

    describe '#modified? / #modified!' do
      it { should respond_to(:modified?) }
      it { should respond_to(:modified!) }

      shared_context('modified specs') do
        let(:modified_key) { @valid_key }
        before { @class = CafeBlog::Core::Configuration(modified_key, @valid_values) }
        subject { @class.instance }

        it { subject.modified?.should be_false }
        it { expect { subject.modified! }.to change { subject.modified? }.from(false).to(true) }
        it { expect { subject.foo = false }.to change { subject.modified? }.from(false).to(true) }
        it { expect { subject.bar = subject.bar }.to_not change { subject.modified? } }
        context do
          before { subject.modified! }
          it { expect { subject.modified! }.to_not change { subject.modified? }.from(true) }
          it { expect { subject.foo = false }.to_not change { subject.modified? }.from(true) }
          it { expect { subject.bar = subject.bar }.to_not change { subject.modified? } }
        end
      end
      include_context('modified specs')

      context '(not exist DB-record)' do
        include_context('modified specs')
        let(:modified_key) { 'no_exist_key' }
      end
    end
  end
end

describe 'migration: 003_create_configurations' do
  context 'migration.up' do
    include_context 'Environment.setup'
    let(:database_migration_params) { {:target => 3} }
    let(:require_models) { false }
    specify 'version is 3' do @database[:schema_info].first[:version].should == 3 end
    specify 'created configurations' do @database.tables.should be_include(:configurations) end
  end
  context 'migration.down' do
    include_context 'Environment.setup'
    let(:require_models) { false }
    before :all do database_demigrate(@database, 0) end

    specify 'dropped configurations' do @database.tables.should_not be_include(:configurations) end
  end
end
