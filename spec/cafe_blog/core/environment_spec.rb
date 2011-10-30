require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'CafeBlog::Core::Environment' do
  def _setup_(*args); CafeBlog::Core::Environment.setup(*args) end
  def _valid_setup_(params = {}); _setup_( {:database => @database}.merge(params) ) end

  before :all do
    @database = Sequel.connect('amalgalite:///')
  end
  before do
    clear_environment
  end

  shared_context 'after .setup' do
    let(:parameter) { {} }
    let(:active_require_models) { false }
    before do
      @called_require_models = false
      unless active_require_models
        CafeBlog::Core::Environment.should_receive(:require_models).once.and_return { @called_require_models = true } # skip models require
      end
      @ins = CafeBlog::Core::Environment.setup( {:database => @database}.merge(parameter) )
    end
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
    
    context 'opt :require [boolean]' do
      include_context('after .setup')
      subject { @called_require_models }

      context 'default is called' do
        it { should be_true }
      end
      context 'called require_modles when :require is true' do
        let(:parameter) { {:require => true} }
        it { should be_true }
      end
      context 'not called require_modles when :require is false' do
        let(:parameter) { {:require => false} }
        let(:active_require_models) { true }
        before do
          CafeBlog::Core::Environment.should_not_receive(:require_models) # skip models require
        end
        it { should be_false }
      end
    end
    
    context 'opt :salt_seed [string]' do
      def _check_(seed); _valid_setup_(:salt_seed => seed, :require => false) end
      
      context 'default value' do
        include_context('after .setup')
        subject { @ins.salt_seed }
        it { should be_a(String) }
        it { should == CafeBlog::Core::Environment::DefaultSaltSeed }
      end

      context 'valid operation' do
        include_context('after .setup')
        let(:parameter) { {:salt_seed => 'valid salt seed value'} }
        subject { @ins.salt_seed }
        it { should == parameter[:salt_seed] }
      end
      
      context 'valid value' do
        it { expect { _check_('this is valid string.') }.to_not raise_error }
        it { expect { _check_('日本語ももちろん通ります') }.to_not raise_error }
        it { expect { _check_('this is valid long-long-long-long-string.') }.to_not raise_error }
        it { expect { _check_('あくまでも種でしかないのでどんなに長い日本語ももちろん通ります。ええ、もう全く問題なし') }.to_not raise_error }
      end
      
      context 'invalid value' do
        it { expect { _check_(:salt_ed => nil) }.to raise_error(ArgumentError) }
        it { expect { _check_('') }.to raise_error(ArgumentError) }
        it { expect { _check_('short.1') }.to raise_error(ArgumentError) }
        it { expect { _check_(Class) }.to raise_error(ArgumentError) }
        it { expect { _check_(:symbol) }.to raise_error(ArgumentError) }
        it { expect { _check_(195123125) }.to raise_error(ArgumentError) }
        it { expect { _check_(Time.now) }.to raise_error(ArgumentError) }
      end
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

  describe '.get_host_address' do
    let(:host_address) { '10-123-11-95.host.example.org' }
    before do
      @address = host_address
      ENV.should_receive(:[]).with('REMOTE_HOST').and_return { @address }
    end
    subject { CafeBlog::Core::Environment.get_host_address }
    it { should == @address }
    context '(not address)' do
      let(:host_address) { nil }
      it { should == 'unknown.host.name' }
    end
  end

  describe '.get_agent' do
    let(:agent) { 'unknown browser/4.5' }
    before do
      @agent = agent
      ENV.should_receive(:[]).with('HTTP_AGENT').and_return { @agent }
    end
    subject { CafeBlog::Core::Environment.get_agent }
    it { should == @agent }
    context '(not address)' do
      let(:agent) { nil }
      it { should == 'unknown/0.0' }
    end
  end

  describe '#database' do
    include_context('after .setup')
    subject { CafeBlog::Core::Environment.instance.database }
    it { should be_kind_of(Sequel::Database) }
  end

  describe '#salt_seed' do
    include_context('after .setup')
    subject { @ins }
    it { should respond_to(:salt_seed) }
    it { should_not respond_to(:salt_seed=) }
  end

  describe '#generate_salt' do
    include_context('after .setup')
    let(:parameter) { {:salt_seed => 'this is password-salt base string.'} }
    subject { @ins }
    it { should respond_to(:generate_salt) }
    it { expect { @ins.generate_salt }.to_not raise_error }
    it { expect { @ins.generate_salt(:base) }.to raise_error(ArgumentError) }
    it { expect { @ins.generate_salt('sample') }.to raise_error(ArgumentError) }

    context 'valid return' do
      subject { @ins.generate_salt }
      it { should be_a(String) }
      it { should match(/^[\da-f]{40}/) }
    end
    context 'match' do
      before do
        @ins.should_receive(:rand).with(65521).and_return { 53014 }
        tm = Time.parse('Tue Oct 11 21:32:16 +0900 2011'); Time.should_receive(:now).and_return { tm }
        Process.should_receive(:pid).and_return { 12244 }
        ENV.should_receive(:[]).with('REMOTE_HOST').and_return { 'ip221-45-153-96.foobar.example.com' }
      end
      subject { @ins.generate_salt }
      it { should == "daf7c9719f5426f4eaf588d4d980a5a57d5c20ee" }
    end
    context 'match' do
      before do
        @ins.should_receive(:rand).with(65521).and_return { 53014 }
        tm, tm2 = Time.parse('Tue Oct 11 21:32:16 +0900 2011'), Time.parse('Tue Oct 11 21:53:23 +0900 2011')
        Time.should_receive(:now).and_return { tm }
        Process.should_receive(:pid).and_return { 12244 }
        ENV.should_receive(:[]).with('REMOTE_HOST').and_return { 'ip221-45-153-96.foobar.example.com' }
        @ins.should_receive(:rand).with(65521).and_return { 1445 }
        Time.should_receive(:now).and_return { tm2 }
        Process.should_receive(:pid).and_return { 12244 }
        ENV.should_receive(:[]).with('REMOTE_HOST').and_return { 'ip221-45-153-96.foobar.example.com' }
      end
      subject { @ins.generate_salt }
      it { should_not == @ins.generate_salt }
    end
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
    let(:active_require_models) { true }

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
