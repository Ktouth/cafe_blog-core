require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CafeBlog do
  it "is module" do
    CafeBlog.should be_instance_of(Module)
  end
end

