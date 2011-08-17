require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'CafeBlog::Core' do
  it 'is module' do
    CafeBlog::Core.should be_instance_of(Module)
  end

  describe 'CafeBlog::Core::VERSION' do
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
end
