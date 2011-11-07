require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'CafeBlog::Core::Configuration' do
  subject { CafeBlog::Core::Configuration }
  it { should be_a(Class) }
end

describe 'CafeBlog::Core.Configuration' do
  before :all do
    @valid_key = 'sample'
    @valid_values = {:foo => true, :bar => 'test', :baz => proc { Hash.new } }
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

  describe 'getter and setter methods' do
    before :all do
      @class = CafeBlog::Core::Configuration(@valid_key, @valid_values)
    end
    subject { @class.instance }
    it { @valid_values.keys.all? {|x| subject.respond_to? x }.should be_true }
    it { @valid_values.keys.all? {|x| subject.respond_to?("#{x}=") }.should be_true }
    it { @valid_values.all? {|k, v| subject.send(k) == (v.is_a?(Proc) ? v.call : v) }.should be_true }
  end
end
