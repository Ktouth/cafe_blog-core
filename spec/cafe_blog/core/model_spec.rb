require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe 'CafeBlog::Core::ModelHelper' do
  include_context 'Environment.setup'
  let(:require_models) { false }
  before :all do
    @database.create_table! :foobar do
      primary_key :ident
      Integer :count, :null => false, :default => 0
      String :subject
      Time :time, :null => false
    end
    @records = [
      {:count => 156, :subject => 'test', :time => Time.now},
      {:count => 10, :subject => 'example', :time => Time.now - 15},
      {:count => 0, :subject => 'foobar', :time => Time.now + 630},
      {:count => 25, :subject => 'sample', :time => Time.now - 893},
      {:count => 81, :subject => 'baz', :time => Time.now - 8888},
      {:count => 6, :subject => '日本語テキスト', :time => Time.now + 11},
    ]
    @database[:foobar].insert_multiple(@records)
  end
  after :all do
    @database.drop_table :foobar rescue nil
  end
  
  shared_context 'sample model' do
    before do
      @model = Class.new(CafeBlog::Core::Model(:foobar))
      @model.class_eval do
        set_restricted_columns :time
      end
    end
    after do
      Sequel::Model::ANONYMOUS_MODEL_CLASSES.delete_if {|k,v| v == @model.superclass }
    end
  end

  subject { CafeBlog::Core::ModelHelper }
  it { should be_a(Module) }
  it { subject.const_get(:ClassMethods).should be_a(Module) }

  context '(Sequel::Model.plugins)' do
    subject { Sequel::Model.plugins }
    it { should include(CafeBlog::Core::ModelHelper) }
  end  

  context '.plugins' do
    include_context 'sample model'
    subject { @model.plugins }
    it { should include(CafeBlog::Core::ModelHelper) }
  end

  describe 'ClassMethods' do
    include_context 'sample model'
    subject { @model }
    it { should respond_to(:set_operation_freeze_columns) }
    it { should respond_to(:remove_column_setters) }
    it { [@model.primary_key, @model.restricted_columns].flatten.should == [:ident, :time] }

    describe '#set_operation_freeze_columns' do
      before :all do @error = CafeBlog::Core::ModelOperationError end
      before { @exist = @model[3]; @new_time = @exist.time + 9999 }
      context '(called no params)' do
        before { @model.set_operation_freeze_columns }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @exist.ident = 999 }.to raise_error(@error) }
        it { expect { @exist.count = 999 }.to change { @exist.count }.to(999) }
        it { expect { @exist.subject = '999' }.to change { @exist.subject }.to('999') }
        it { expect { @exist.time = @new_time }.to raise_error(@error) }
      end
      context '(called 1 params)' do
        before { @model.set_operation_freeze_columns :ident }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @exist.ident = 999 }.to raise_error(@error) }
        it { expect { @exist.count = 999 }.to change { @exist.count }.to(999) }
        it { expect { @exist.subject = '999' }.to change { @exist.subject }.to('999') }
        it { expect { @exist.time = @new_time }.to change { @exist.time }.to(@new_time) }
      end
      context '(called 3 params)' do
        before { @model.set_operation_freeze_columns :ident, :count, :subject }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @exist.ident = 999 }.to raise_error(@error) }
        it { expect { @exist.count = 999 }.to raise_error(@error) }
        it { expect { @exist.subject = '999' }.to raise_error(@error) }
        it { expect { @exist.time = @new_time }.to change { @exist.time }.to(@new_time) }
      end
      context '(called 0+3 params)' do
        before { @model.set_operation_freeze_columns; @model.set_operation_freeze_columns :ident, :count, :subject }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @exist.ident = 999 }.to raise_error(@error) }
        it { expect { @exist.count = 999 }.to raise_error(@error) }
        it { expect { @exist.subject = '999' }.to raise_error(@error) }
        it { expect { @exist.time = @new_time }.to raise_error(@error) }
      end
      context 'invalid params' do
        specify 'no column name' do expect { @model.set_operation_freeze_columns :no_name }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.set_operation_freeze_columns 'ident' }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.set_operation_freeze_columns 123456 }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.set_operation_freeze_columns /regexp/ }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.set_operation_freeze_columns nil }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.set_operation_freeze_columns false }.to raise_error(ArgumentError) end
      end
    end

    describe '#remove_column_setters' do
      before { @exist = @model[3]; @new_time = @exist.time + 9999 }
      context '(called invalid params)' do
        it { expect { @model.remove_column_setters }.to raise_error(ArgumentError) }
        it { expect { @model.remove_column_setters :not_column }.to raise_error(ArgumentError) }
        it { expect { @model.remove_column_setters 1235489 }.to raise_error(ArgumentError) }
        it { expect { @model.remove_column_setters 'test_method' }.to raise_error(ArgumentError) }
        it { expect { @model.remove_column_setters /regexp/ }.to raise_error(ArgumentError) }
        it { expect { @model.remove_column_setters nil, true, false }.to raise_error(ArgumentError) }
      end
      context '(called 1 params)' do
        before { @item, @alt = @model[2], Class.new(CafeBlog::Core::Model(:foobar)).new }
        it { expect { @model.remove_column_setters :time }.to_not raise_error }
        it { expect { @model.remove_column_setters :time }.to change { @item.respond_to?(:time=) }.from(true).to(false) }
        it { expect { @model.remove_column_setters :time }.to change { @alt.respond_to?(:time=) }.to(false) }
        it { expect { @model.remove_column_setters :time; @item[:time] = @item.time + 10000 }.to change { @item.time }.by(10000) }
      end
      context '(called many params)' do
        before { @item, @alt = @model[4], Class.new(CafeBlog::Core::Model(:foobar)).new }
        it { expect { @model.remove_column_setters :ident, :count, :time }.to_not raise_error }
        it { expect { @model.remove_column_setters :ident, :count, :time }.to change { @item.respond_to?(:time=) }.from(true).to(false) }
        it { expect { @model.remove_column_setters :ident, :count, :time }.to change { @alt.respond_to?(:ident=) }.to(false) }
        it { expect { @model.remove_column_setters :ident, :count, :time; @item[:count] = @item.count + 10000 }.to change { @item.count }.by(10000) }
        it { expect { @model.remove_column_setters :time, :time, :time }.to_not raise_error }
        it { expect { @model.remove_column_setters :ident; @model.remove_column_setters :ident }.to_not raise_error }
      end
      
      context '(remove all setters)' do
        before { @model.class_eval { def time=(value); :result_item_ok end }; @item = @model[3] }
        it { (@item.send :time=, 12113).should == :result_item_ok }
        it { expect { @model.remove_column_setters :time }.to_not raise_error }
        it { expect { @model.remove_column_setters :time }.to change { @item.respond_to?(:time=) }.from(true).to(false) }
      end
    end
  end
end
