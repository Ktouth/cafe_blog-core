require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'CafeBlog::Core::Environment' do
  def _setup_(*args); CafeBlog::Core::Environment.setup(*args) end
  def _valid_setup_(params = {}); _setup_( {:database => @database}.merge(params) ) end

  before :all do
    @database = Sequel.connect('sqlite:///')
  end
  before do
    clear_environment
  end

  shared_context 'after .setup' do
    let(:parameter) { {} }
    before { @ins = CafeBlog::Core::Environment.setup( {:database => @database}.merge(parameter) ) }
  end

  subject { CafeBlog::Core::Environment }
  it { should be_instance_of(Class) }
  it { should_not respond_to(:new) }

  describe '.setup' do
    context 'received except for hash parameter' do
      it { expect { _setup_(:nil) }.to raise_error(ArgumentError) }
    end
    context 'received no parameter' do
      it { expect { _setup_ }.to raise_error(ArgumentError) }
    end
    context 'received except for sequel database' do
      it { expect { _setup_(:database => 'bad parameter') }.to raise_error(ArgumentError) }
    end
    context 'received no :database parameter' do
      it { expect { _setup_(:sample => 123456789) }.to raise_error(ArgumentError) }
    end
    
    context 'result value' do
      include_context('after .setup')
      subject { @ins }
      it { should be_instance_of(CafeBlog::Core::Environment) }
    end
  end

  describe '.instance' do
    subject { CafeBlog::Core::Environment.instance }
    context 'before .setup' do
      it { should be_nil }
    end
    context 'after .setup' do
      include_context('after .setup')
      it { should == @ins }
      it { expect { _valid_setup_ }.to raise_error(CafeBlog::Core::ApplicationError) }
    end
  end
  
  describe '.check_instance' do
    subject { CafeBlog::Core::Environment.check_instance }
    context 'before .setup' do
      it { expect { CafeBlog::Core::Environment.check_instance }.to raise_error(CafeBlog::Core::ApplicationError) }
    end
    context 'after .setup' do
      include_context('after .setup')
      it { should == @ins }
    end
  end

  describe '#database' do
    include_context('after .setup')
    subject { CafeBlog::Core::Environment.instance.database }
    it { should be_kind_of(Sequel::Database) }
  end

  describe '(.require_models)' do
    before :all do
      @model_dir = File.expand_path('cafe_blog/core/model', LibDirBase)
      @requires = %w(author article tag comment file image impression)
      @files = @requires.map {|x| "#{x}.rb" }
      @requires.map! {|x| "cafe_blog/core/model/#{x}" }
    end
    include_context 'after .setup'
    let(:parameter) { {:require => false} }

    subject { CafeBlog::Core::Environment }
    it { should_not respond_to(:require_models) }
    it { should be_respond_to(:require_models, true) }

    context 'method behavior check' do
      before do
        glob = Dir.should_receive(:glob).with("#{@model_dir}/*.{rb,so,o,dll}").once.ordered
        @call_params = []
        @files.zip(@requires).each do |f, r|
          @call_params.push r
          glob.and_yield(f)
          CafeBlog::Core::Environment.should_receive(:require).with(r).once.ordered
        end
        
        CafeBlog::Core::Environment.__send__(:require_models)
      end

      subject { @call_params }
      it { should == @requires }
    end
  end
end
