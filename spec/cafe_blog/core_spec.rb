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
end
