require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::Author' do
  include_context 'Environment.setup'

  subject { CafeBlog::Core::Model::Author }
  it { should be_instance_of(Class) }
  it { should < Sequel::Model }
  context '.simple_table' do
    subject { CafeBlog::Core::Model::Author.simple_table }
    it { should == @database.literal(:authors) }
  end
end
