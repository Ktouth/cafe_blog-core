require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper')

describe NotNaughty::UniquenessValidation do
  include_context 'Environment.setup'
  let(:database_migration_params) { {:target => 0} }
  let(:require_models) { false }
  before :all do
    @database.create_table! :foos do
      primary_key :id
      String :name, :null => true, :unique => true
      String :code, :null => false, :unique => true
    end
    @records = [
      {:name => 'test', :code => 'foo'},
      {:name => 'sample', :code => 'bar'},
      {:name => 'サンプル', :code => 'baz'},
      {:name => 'テスト', :code => 'test'},
      {:name => 'example', :code => 'example'},
      {:name => nil, :code => ''},
    ]
    @database[:foos].insert_multiple(@records)
  end
  after :all do
    @database.drop_table :foos rescue nil
  end
  before do
    @model = Class.new(Sequel::Model(@database[:foos]))
    @model.class_eval do
      plugin :notnaughty rescue nil
      validates(:name) { uniqueness :allow_nil => true }
      validates(:code) { uniqueness }
    end
  end
  after do
    Sequel::Model::ANONYMOUS_MODEL_CLASSES.delete_if {|k, v| v == @model.superclass } rescue nil
  end

  subject { NotNaughty::UniquenessValidation }
  it { should be_a(Class) }
  it { should < NotNaughty::Validation }

  def new_arg(sym, base)
    i = 0
    loop do
      result = '%s%03d' % [base, i += 1]
      return result if @database[:foos].filter(sym => result).empty?
    end
  end      

  context ':name uniqueness test' do
    before do
      @item = @model.new(:code => new_arg(:code, 'newCode'))
      @exist = @model[3]      
    end
    after do
      @model.exclude(:name => @records.map {|v| v[:name] }).delete
    end

    it { expect { @item.name= 'newItem'; @item.save }.to_not raise_error(Sequel::ValidationFailed) }
    it { expect { @item.name= 'newItem2'; @item.save }.to change { @model.count }.by(1) }
    it { expect { @item.name= @exist.name; @item.save }.to raise_error(Sequel::ValidationFailed) }
    it { expect { @item.name= nil; @item.save; @model.create(:code => new_arg(:code, 'forward')) }.to_not raise_error(Sequel::ValidationFailed) }
    it { expect { @item.name= nil; @item.save; @model.create(:code => new_arg(:code, 'forward')) }.to change { @model.count }.by(2) }

    it { expect { @exist.name= 'newItem3'; @exist.save }.to_not raise_error(Sequel::ValidationFailed) }
    it { expect { @exist.name= 'newItem4'; @exist.save }.to_not change { @model.count } }
  end

  context ':code uniqueness test' do
    before do
      @item = @model.new(:name => new_arg(:name, 'newName'))
      @exist = @model[3]      
    end
    after do
      @model.exclude(:name => @records.map {|v| v[:name] }).delete
    end

    it { expect { @item.code= 'newItem'; @item.save }.to_not raise_error(Sequel::ValidationFailed) }
    it { expect { @item.code= 'newItem2'; @item.save }.to change { @model.count }.by(1) }
    it { expect { @item.code= @exist.code; @item.save }.to raise_error(Sequel::ValidationFailed) }
    it { expect { @item.code= ''; @item.save }.to raise_error(Sequel::ValidationFailed) }

    it { expect { @exist.code= 'newItem3'; @exist.save }.to_not raise_error(Sequel::ValidationFailed) }
    it { expect { @exist.code= 'newItem4'; @exist.save }.to_not change { @model.count } }
  end
end
