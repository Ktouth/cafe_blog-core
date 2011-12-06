require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
module ModelHelperSpecHelper
  def self.remove_all_const
    constants.each {|x| remove_const(x) }
  end
end
describe 'CafeBlog::Core::ModelHelper' do
  include_context 'Environment.setup'
  let(:require_models) { false }
  before :all do
    @database.create_table! :barbaz do
      primary_key :key
      String :name, :null => false
    end
    @database.create_table! :foobar do
      primary_key :ident
      Integer :count, :null => false, :default => 0
      String :subject
      Time :time, :null => false
      foreign_key :barbaz_key, :barbaz, :null => true, :default => nil
      foreign_key :barbaz_key2, :barbaz, :null => true, :default => nil
      foreign_key :barbaz_key3, :barbaz, :null => true, :default => nil
    end
    @database.create_table! :b2f do
      foreign_key :barbaz_id, :barbaz, :null => true, :default => nil
      foreign_key :foobar_id, :foobar, :null => true, :default => nil
      index [:barbaz_id, :foobar_id]
    end
    @names = [
      {:name => 'admin'},
      {:name => 'example'},
      {:name => 'test'},
      {:name => 'whois'},
    ]
    @database[:barbaz].insert_multiple(@names)
    @records = [
      {:count => 156, :subject => 'test', :time => Time.now, :barbaz_key => 2},
      {:count => 10, :subject => 'example', :time => Time.now - 15},
      {:count => 0, :subject => 'foobar', :time => Time.now + 630, :barbaz_key => 3},
      {:count => 25, :subject => 'sample', :time => Time.now - 893},
      {:count => 81, :subject => 'baz', :time => Time.now - 8888},
      {:count => 6, :subject => '日本語テキスト', :time => Time.now + 11, :barbaz_key => 1},
    ]
    @database[:foobar].insert_multiple(@records)
    @links = [
      {:barbaz_id => 1, :foobar_id => 1},
      {:barbaz_id => 2, :foobar_id => 5},
      {:barbaz_id => 1, :foobar_id => 2},
      {:barbaz_id => 1, :foobar_id => 3},
      {:barbaz_id => 3, :foobar_id => 1},
      {:barbaz_id => 2, :foobar_id => 1},
    ]
    @database[:b2f].insert_multiple(@links)
  end
  after :all do
    @database.drop_table :b2f rescue nil
    @database.drop_table :foobar rescue nil
    @database.drop_table :barbaz rescue nil
  end
  
  shared_context 'sample model' do
    before do
      @barbaz_model = ModelHelperSpecHelper::Barbaz = Class.new(CafeBlog::Core::Model(:barbaz))
      @model = ModelHelperSpecHelper::Foobar = Class.new(CafeBlog::Core::Model(:foobar))
      @model.class_eval do
        set_restricted_columns :time
        many_to_one :barbaz, :key => :barbaz_key
      end
      @barbaz_model.one_to_many :foobar, :key => :barbaz_key, :class => @model
      @barbaz_model.one_to_one :foobar_oo, :key => :barbaz_key, :class => @model
      @barbaz_model.many_to_many :links, :class => @model, :left_key => :barbaz_id, :right_key => :foobar_id, :join_table => :b2f
    end
    after do
      Sequel::Model::ANONYMOUS_MODEL_CLASSES.delete_if {|k,v| v == @model.superclass or v == @barbaz_model.superclass }
      ModelHelperSpecHelper.remove_all_const
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
    specify { [@model.primary_key, @model.restricted_columns].flatten.should == [:ident, :time] }

    it { should respond_to(:set_operation_freeze_columns) }
    it { should respond_to(:remove_column_setters) }
    it { should respond_to(:alt_column_accessors) }
    it { should respond_to(:protected_foreign_keys) }

    describe '#set_operation_freeze_columns' do
      before :all do @error = CafeBlog::Core::ModelOperationError end
      before do
        @exist = @model[3]; @new_time = @exist.time + 9999
        @barbaz = @barbaz_model.order_by(:key).first
      end
      context '(called no params)' do
        before { @model.set_operation_freeze_columns }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @model.new.ident = 999 }.to_not raise_error(@error) }
        it { expect { @exist.ident = 999 }.to raise_error(@error) }
        it { expect { @exist.count = 999 }.to change { @exist.count }.to(999) }
        it { expect { @exist.subject = '999' }.to change { @exist.subject }.to('999') }
        it { expect { @model.new.time = @new_time }.to_not raise_error(@error) }
        it { expect { @exist.time = @new_time }.to raise_error(@error) }
      end
      context '(called 1 params)' do
        before { @model.set_operation_freeze_columns :ident }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @model.new.ident = 999 }.to_not raise_error(@error) }
        it { expect { @exist.ident = 999 }.to raise_error(@error) }
        it { expect { @exist.count = 999 }.to change { @exist.count }.to(999) }
        it { expect { @exist.subject = '999' }.to change { @exist.subject }.to('999') }
        it { expect { @model.new.time = @new_time }.to_not raise_error(@error) }
        it { expect { @exist.time = @new_time }.to change { @exist.time }.to(@new_time) }
      end
      context '(called 1 params / association columns)' do
        before { @model.set_operation_freeze_columns :barbaz }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111, :barbaz => @barbaz) }.to_not raise_error(@error) }
        it { expect { @model.new(:ident => 12, :count => 511, :subject => 'newItem2', :time => Time.now - 511111, :barbaz_key => @barbaz.key) }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz = @barbaz }.to_not raise_error(@error) }
        it { expect { @exist.barbaz = @barbaz }.to raise_error(@error) }
        it { expect { @exist.barbaz_key }.to raise_error(NoMethodError) }
        it { @exist[:barbaz_key].should == 3 }
        it { @exist.instance_eval { barbaz_key }.should == 3 }
        it { expect { @exist.barbaz_key = @barbaz.key }.to raise_error(NoMethodError) }
        it { expect { @exist[:barbaz_key] = @barbaz.key }.to_not raise_error(@error) }
        it { expect { _key = @barbaz.key; @exist.instance_eval { self.barbaz_key = _key } }.to raise_error(@error) }
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
        specify 'one_to_one association' do expect { @barbaz_model.set_operation_freeze_columns :foobar_oo }.to raise_error(ArgumentError) end
        specify 'one_to_many association' do expect { @barbaz_model.set_operation_freeze_columns :foobar }.to raise_error(ArgumentError) end
        specify 'many_to_many association' do expect { @barbaz_model.set_operation_freeze_columns :links }.to raise_error(ArgumentError) end
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
      
    describe '#alt_column_accessors' do
      before { @exist = @model[3] }
      context '(called invalid params)' do
        it { expect { @model.alt_column_accessors }.to raise_error(ArgumentError) }
        it { expect { @model.alt_column_accessors :ident }.to raise_error(ArgumentError) }
        it { expect { @model.alt_column_accessors :time }.to raise_error(ArgumentError) }
        it { expect { @model.alt_column_accessors 1235489 }.to raise_error(ArgumentError) }
        it { expect { @model.alt_column_accessors 'test_method' }.to raise_error(ArgumentError) }
        it { expect { @model.alt_column_accessors /regexp/ }.to raise_error(ArgumentError) }
        it { expect { @model.alt_column_accessors nil, true, false }.to raise_error(ArgumentError) }
      end
      context '(called 1 params)' do
        before { @item, @alt = @model[2], Class.new(CafeBlog::Core::Model(:foobar)).new }
        it { expect { @model.alt_column_accessors :alter }.to_not raise_error }
        it { expect { @model.alt_column_accessors :alter }.to change { @item.respond_to?(:alter) }.from(false).to(true) }
        it { expect { @model.alt_column_accessors :alter }.to change { @item.respond_to?(:alter=) }.from(false).to(true) }
        it { expect { @model.alt_column_accessors :alter }.to_not change { @alt.respond_to?(:alter) }.to(true) }
        it { expect { @model.alt_column_accessors :alter }.to_not change { @alt.respond_to?(:alter=) }.to(true) }
        it { expect { @model.alt_column_accessors :alter; @item.alter = nil }.to_not change { @item.modified? } }
        it { expect { @model.alt_column_accessors :alter; @item.alter = :test }.to change { @item.modified? }.to(true) }
        it { expect { @model.alt_column_accessors :alter; @item.alter = 123456 }.to_not change { @item.changed_columns } }
        it { expect { @model.alt_column_accessors :alter; @item.alter = /regexp/ }.to_not change { @item.values.include?(:alter) } }
      end
      context '(called many params)' do
        before { @item, @alt = @model[4], Class.new(CafeBlog::Core::Model(:foobar)).new }
        it { expect { @model.alt_column_accessors :alter, :context }.to_not raise_error }
        it { expect { @model.alt_column_accessors :alter, :context }.to change { @item.respond_to?(:alter) }.from(false).to(true) }
        it { expect { @model.alt_column_accessors :alter, :context }.to change { @item.respond_to?(:alter=) }.from(false).to(true) }
        it { expect { @model.alt_column_accessors :alter, :context }.to_not change { @alt.respond_to?(:context) }.to(true) }
        it { expect { @model.alt_column_accessors :alter, :context }.to_not change { @alt.respond_to?(:context=) }.to(true) }
        it { expect { @model.alt_column_accessors :alter, :context; @item.context = nil }.to_not change { @item.modified? } }
        it { expect { @model.alt_column_accessors :alter, :context; @item.context = :test }.to change { @item.modified? }.to(true) }
        it { expect { @model.alt_column_accessors :alter, :context; @item.context = 123456 }.to_not change { @item.changed_columns } }
        it { expect { @model.alt_column_accessors :alter, :context; @item.context = /regexp/ }.to_not change { @item.values.include?(:alter) } }
      end
    end

    describe '#protected_foreign_keys' do
      before :all do @error = NoMethodError end
      before do
        @model.many_to_one :bar, :key => :barbaz_key2
        @model.many_to_one :bbbbb, :key => :barbaz_key3

        @exist = @model[3]; @new_time = @exist.time + 9999
        @barbaz = @barbaz_model.order_by(:key).first
      end
      context '(called no params)' do
        before { @model.protected_foreign_keys }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.bar }.to_not raise_error(@error) }
        it { expect { @model.new.bar = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.bbbbb }.to_not raise_error(@error) }
        it { expect { @model.new.bbbbb = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz_key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key = @barbaz.key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key2 }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key2 = @barbaz.key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key3 }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key3 = @barbaz.key }.to raise_error(@error) }
      end
      context '(called 1 params)' do
        before { @model.protected_foreign_keys :barbaz }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.bar }.to_not raise_error(@error) }
        it { expect { @model.new.bar = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.bbbbb }.to_not raise_error(@error) }
        it { expect { @model.new.bbbbb = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz_key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key = @barbaz.key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key2 }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz_key2 = @barbaz.key }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz_key3 }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz_key3 = @barbaz.key }.to_not raise_error(@error) }
      end
      context '(called 0+2 params)' do
        before { @model.protected_foreign_keys; @model.protected_foreign_keys :bbbbb, :barbaz }
        it { expect { @model.new(:ident => 11, :count => 511, :subject => 'newItem', :time => Time.now - 511111) }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.bar }.to_not raise_error(@error) }
        it { expect { @model.new.bar = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.bbbbb }.to_not raise_error(@error) }
        it { expect { @model.new.bbbbb = @barbaz }.to_not raise_error(@error) }
        it { expect { @model.new.barbaz_key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key = @barbaz.key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key2 }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key2 = @barbaz.key }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key3 }.to raise_error(@error) }
        it { expect { @model.new.barbaz_key3 = @barbaz.key }.to raise_error(@error) }
      end
      context 'invalid params' do
        specify 'no column name' do expect { @model.protected_foreign_keys :no_name }.to raise_error(ArgumentError) end
        specify 'no association name' do expect { @model.protected_foreign_keys :subject }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.protected_foreign_keys 'ident' }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.protected_foreign_keys 123456 }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.protected_foreign_keys /regexp/ }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.protected_foreign_keys nil }.to raise_error(ArgumentError) end
        specify 'not symbol' do expect { @model.protected_foreign_keys false }.to raise_error(ArgumentError) end
        specify 'one_to_one association' do expect { @barbaz_model.protected_foreign_keys :foobar_oo }.to raise_error(ArgumentError) end
        specify 'one_to_many association' do expect { @barbaz_model.protected_foreign_keys :foobar }.to raise_error(ArgumentError) end
        specify 'many_to_many association' do expect { @barbaz_model.protected_foreign_keys :links }.to raise_error(ArgumentError) end
      end
    end
  end
end
