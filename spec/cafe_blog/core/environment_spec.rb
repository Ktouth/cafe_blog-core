require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'CafeBlog::Core::Environment' do
  before do
    CafeBlog::Core::Environment.instance_variable_set(:@instance, nil)
  end
  def setup_parameter(params = {})
    {:database => Sequel.connect('sqlite:/')}.merge(params)
  end

  it 'is class' do
    CafeBlog::Core::Environment.should be_instance_of(Class)
  end

  it '.new is not public method' do
    lambda { CafeBlog::Core::Environment.new }.should raise_error(NoMethodError)
  end

  describe '.setup' do
    it 'raise error received except for hash parameter' do
      lambda { CafeBlog::Core::Environment.setup(:nil) }.should raise_error(ArgumentError)
    end
    it 'raise error received no parameter' do
      lambda { CafeBlog::Core::Environment.setup() }.should raise_error(ArgumentError)
    end
    it 'raise error received except for sequel database' do
      lambda { CafeBlog::Core::Environment.setup(:database => 'bad parameter') }.should raise_error(ArgumentError)
    end
    it 'raise error received no :database parameter' do
      lambda { CafeBlog::Core::Environment.setup(:sample => 123456789) }.should raise_error(ArgumentError)
    end
    
    it 'return Environment instance' do
      CafeBlog::Core::Environment.setup(setup_parameter).should be_instance_of(CafeBlog::Core::Environment)
    end
  end

  describe '.instance' do
    it 'is nil before setup' do
      CafeBlog::Core::Environment.instance.should be_nil
    end
    it 'is set instance after setup' do
      ins = CafeBlog::Core::Environment.setup(setup_parameter)
      CafeBlog::Core::Environment.instance.should == ins
    end

    it 'raise already created instance' do
      CafeBlog::Core::Environment.setup(setup_parameter)
      lambda { CafeBlog::Core::Environment.setup(setup_parameter) }.should raise_error(CafeBlog::Core::ApplicationError)
    end
  end
  
  describe '.check_instance' do
    before :each do
      CafeBlog::Core::Environment.instance_eval { @instance = nil }
    end
    it 'raise ApplicationError before setup' do
      lambda { CafeBlog::Core::Environment.check_instance }.should raise_error(CafeBlog::Core::ApplicationError)
    end
    it 'is return instance after setup' do
      ins = CafeBlog::Core::Environment.setup(setup_parameter)
      CafeBlog::Core::Environment.check_instance.should == ins
    end
  end

  describe '#database' do
    before :all do
      @database = Sequel.connect('sqlite:///')
    end
    before :each do
      CafeBlog::Core::Environment.instance_eval { @instance = nil }
      @env = CafeBlog::Core::Environment.setup(:database => @database)
    end

    it 'is instance of Sequel::Database' do
      @env.database.should be_kind_of(Sequel::Database)
    end
  end  
end
