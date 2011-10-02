require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CafeBlog::Core do
  subject { CafeBlog::Core }
  it { should be_instance_of(Module) }

  describe '::VERSION' do
    before :all do
      @path = File.expand_path(File.dirname(__FILE__) + '/../../VERSION')
    end
    
    context 'VERSION file' do
      subject { File }
      it { should exist(@path) }
    end

    subject { CafeBlog::Core::VERSION }
    it { should match(/^\d+\.\d+\.\d+$/) }
    it { should == File.open(@path) {|x| x.read } }
  end

  describe '::Model' do
    subject { CafeBlog::Core::Model }
    it { should be_instance_of(Module) }
  end

  describe '::ApplicationError' do
    subject { CafeBlog::Core::ApplicationError }
    it { should be_instance_of(Class) }
    it { should < Exception }
  end

  describe '::ModelOperationError' do
    subject { CafeBlog::Core::ModelOperationError }
    it { should be_instance_of(Class) }
    it { should < CafeBlog::Core::ApplicationError }
  end

  describe '.model' do
    before do
      clear_environment
    end

    context 'recieved without parameter' do
      it { expect { CafeBlog::Core.model }.to raise_error(ArgumentError) }
    end

    context 'recieved with not symbol' do
      it { expect { CafeBlog::Core.model('sample') }.to raise_error(ArgumentError) }
    end

    context 'called before environment setup' do
      it { expect { CafeBlog::Core.model(:windows) }.to raise_error(CafeBlog::Core::ApplicationError) }
    end

    context 'without no database-table' do
      before do
        CafeBlog::Core::Environment.setup(:database => Sequel.connect('sqlite:///'))        
      end
      context '(dummy table)' do
        subject { CafeBlog::Core::Environment.instance.database }
        it { should_not be_table_exist(:bad_authors) }
      end

      it { expect { CafeBlog::Core.model(:bad_authors) }.to raise_error(CafeBlog::Core::ModelOperationError) }
    end

    context 'return value' do
      before do
        db = Sequel.connect('sqlite:///')
        db.create_table :authors do
          primary_key :id
          String :name, :unique => true, :null => false, :index => true
        end
        CafeBlog::Core::Environment.setup(:database => db)
      end
      context '(dummy table)' do
        subject { CafeBlog::Core::Environment.instance.database }
        it { should be_table_exist(:authors) }
      end

      subject { CafeBlog::Core.model(:authors) }
      it { should be_instance_of(Class) }
      it { should < Sequel::Model }
    end
  end
end
