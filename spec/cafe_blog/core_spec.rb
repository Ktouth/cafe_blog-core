require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CafeBlog::Core do
  it 'is module' do
    CafeBlog::Core.should be_instance_of(Module)
  end
end
