require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'CafeBlog::Core' do
  it 'is module' do
    CafeBlog::Core.should be_instance_of(Module)
  end

  describe '::VERSION' do
    before :all do
      @path = File.expand_path(File.dirname(__FILE__) + '/../../VERSION')
    end
    
    it 'VERSION file is exist' do
      File.exist?(@path).should be_true
    end

    it 'is version string' do
      /^\d+\.\d+\.\d+$/.match(CafeBlog::Core::VERSION).should be_true
    end

    it 'is match VERSION file' do
      CafeBlog::Core::VERSION.should == (File.open(@path) {|x| x.read })
    end
  end

  describe '::Model' do
    it 'is module' do
      CafeBlog::Core::Model.should be_instance_of(Module)
    end
  end

  describe '::ApplicationError' do
    it 'is exception class' do
      CafeBlog::Core::ApplicationError.should be_instance_of(Class)
      CafeBlog::Core::ApplicationError.superclass.should == Exception
    end
  end

  describe '::ModelOperationError' do
    it 'is exception class' do
      CafeBlog::Core::ModelOperationError.should be_instance_of(Class)
      CafeBlog::Core::ModelOperationError.superclass.should == CafeBlog::Core::ApplicationError
    end
  end

  describe '.model' do
    before :each do
      CafeBlog::Core::Environment.instance_eval { @instance = nil }
    end

    it 'raise ArgumentError when recieved without parameter' do
      lambda { CafeBlog::Core.model }.should raise_error(ArgumentError)
    end

    it 'raise ArgumentError when recieved with not symbol' do
      lambda { CafeBlog::Core.model('sample') }.should raise_error(ArgumentError)
    end

    it 'raise ModelOperationError when called before environment setup' do
      CafeBlog::Core::Environment.instance.should be_nil
      lambda { CafeBlog::Core.model(:windows) }.should raise_error(CafeBlog::Core::ModelOperationError)
    end

    it 'raise any exeption custom model class without no table' do
      CafeBlog::Core::Environment.setup(:database => Sequel.connect('sqlite:///'))
      CafeBlog::Core::Environment.instance.database.should_not be_table_exist(:bad_authors)
      model = CafeBlog::Core.model(:bad_authors)
    end

    it 'return custom model class' do
      db = Sequel.connect('sqlite:///')
      db.create_table :authors do
        primary_key :id
        String :name, :unique => true, :null => false, :index => true
      end
      db.should be_table_exist(:authors)

      CafeBlog::Core::Environment.setup(:database => db)
      model = CafeBlog::Core.model(:authors)
    end
  end
end
