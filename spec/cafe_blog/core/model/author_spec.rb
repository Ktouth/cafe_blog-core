require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe 'CafeBlog::Core::Model::Author' do
  include_context 'Environment.setup'
  shared_context 'authors reset' do
    before :all do
      database_resetdata(@database)
    end
  end
  def valid_args(args = {})
    codes = @database[:authors].map {|r| r[:code] }
    code = nil
    unless args[:code]
      i = 1
      loop do
        code = 'foobar_baz%02d' % i
        break unless codes.include?(code)
        i += 1
      end
    end
    names = @database[:authors].map {|r| r[:name] }
    name = nil
    unless args[:name]
      i = 1
      loop do
        name = '%s_name%d' % [code,i]
        break unless names.include?(name)
        i += 1
      end
    end
    {:id => nil, :code => code, :name => name }.merge(args)
  end

  subject { CafeBlog::Core::Model::Author }
  it { should be_instance_of(Class) }
  it { should < Sequel::Model }
  context '.simple_table' do
    subject { CafeBlog::Core::Model::Author.simple_table }
    it { should == @database.literal(:authors) }
  end
  context '.primary_key' do
    subject { CafeBlog::Core::Model::Author.primary_key }
    it { should == :id }
  end
  context '.restrict_primary_key?' do
    subject { CafeBlog::Core::Model::Author.restrict_primary_key? }
    it { should be_true }
  end

  context '.setter_methods' do
    subject { CafeBlog::Core::Model::Author.setter_methods }
    it { should_not include(:id=) }
  end

  describe 'instance methods' do
    before do
      @author = CafeBlog::Core::Model::Author.new
      @admin ||= CafeBlog::Core::Model::Author[:id => 1]
    end
    def args_set(*excepts)
      valid_args.tap {|args| excepts.each {|x| args.delete(x) } }.each do |key, value|
        @author.send("#{key}=", value)
      end
    end
    specify '@admin is exist' do @admin.should_not be_nil end
    subject { @author }

    it { should respond_to(:id) }
    it { should respond_to(:code) }
    it { should respond_to(:name) }
    it { should respond_to(:mailto) }
    it { should respond_to(:crypted_password) }
    it { should_not be_respond_to(:crypted_password=) }
    it { should respond_to(:password_salt) }
    it { should_not be_respond_to(:password_salt=) }

    context '#id' do
      include_context 'authors reset'
      before { args_set(:id) }
      subject { @author.id }

      it { should be_nil }
      it { expect { @author.id = 15; @author.save }.to change { [@author.id, @author.new?] }.from([nil, true]).to([15, false]) }
      it { expect { CafeBlog::Core::Model::Author.set(valid_args(:id => nil)) }.to raise_error }
      it { expect { @new = CafeBlog::Core::Model::Author.insert(valid_args(:id => nil)) }.to change { @new }.from(nil).to(16) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:id => @admin.id)) }.to raise_error }
      it { expect { @admin.id = 5932 }.to raise_error }
    end

    context '#code' do
      include_context 'authors reset'
      before { args_set(:code) }
      subject { @author.code }

      it { should be_nil }
      it { expect { @author.code = 'dummy_code'; @author.save }.to change { [@author.code, @author.new?] }.from([nil, true]).to(['dummy_code', false]) }
      it { expect { @author.code = 'foobar128123'; @author.save }.to change { [@author.code, @author.new?] }.from([nil, true]).to(['foobar128123', false]) }
      it { expect { @author.code = 'asadfdefg'; @author.save }.to change { [@author.code, @author.new?] }.from([nil, true]).to(['asadfdefg', false]) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:code => nil)) }.to raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:code => @admin.code)) }.to raise_error }
      it { expect { @author.code = ''; @author.save }.to raise_error }
      it { expect { @author.code = '123564896123'; @author.save }.to raise_error }
      it { expect { @author.code = 'ab'; @author.save }.to raise_error }
      it { expect { @author.code = 'asadf456asdfa456adf7a89adsf123'; @author.save }.to raise_error }
      it { expect { @author.code = '123456789'; @author.save }.to raise_error }
      it { expect { @author.code = '日本語'; @author.save }.to raise_error }
      it { expect { @author.code = 'BADtest123'; @author.save }.to raise_error }
      it { expect { @author.code = '__test__'; @author.save }.to raise_error }
      it { expect { @admin.code = 'alter_admin' }.to raise_error }
    end

    context '#name' do
      include_context 'authors reset'
      before { args_set(:name) }
      subject { @author.name }

      it { should be_nil }
      it { expect { @author.name = 'dummy_code'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['dummy_code', false]) }
      it { expect { @author.name = 'foobar128123'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['foobar128123', false]) }
      it { expect { @author.name = '123564896123'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['123564896123', false]) }
      it { expect { @author.name = 'asadf456asdfa456adf7a89adsf123'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['asadf456asdfa456adf7a89adsf123', false]) }
      it { expect { @author.name = 'asa'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['asa', false]) }
      it { expect { @author.name = '123456789'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['123456789', false]) }
      it { expect { @author.name = '日本語'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['日本語', false]) }
      it { expect { @author.name = 'BADtest123'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['BADtest123', false]) }
      it { expect { @author.name = '__test__'; @author.save }.to change { [@author.name, @author.new?] }.from([nil, true]).to(['__test__', false]) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:name => nil)) }.to raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:name => @admin.name)) }.to raise_error }
      it { expect { @author.name = ''; @author.save }.to raise_error }
      it { expect { @author.name = 'ab'; @author.save }.to raise_error }
      it { expect { @author.name = '短い'; @author.save }.to raise_error }
    end

    context '#mailto' do
      include_context 'authors reset'
      before { args_set(:mailto) }
      subject { @author.mailto }

      it { should be_nil }
      it { expect { @author.mailto = nil; @author.save }.to change { [@author.mailto, @author.new?] }.from([nil, true]).to([nil, false]) }
      it { expect { @author.mailto = 'valid@mailto.net'; @author.save }.to change { [@author.mailto, @author.new?] }.from([nil, true]).to(['valid@mailto.net', false]) }
      it { expect { @author.mailto = 'argument.set_ok@ore.ex-sample.net'; @author.save }.to change { [@author.mailto, @author.new?] }.from([nil, true]).to(['argument.set_ok@ore.ex-sample.net', false]) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:mailto => nil)) }.to_not raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:mailto => 'migration@sequel.class.org')) }.to_not raise_error }
      it { expect { @author.mailto = ''; @author.save }.to raise_error }
      it { expect { @author.mailto = 'ab'; @author.save }.to raise_error }
      it { expect { @author.mailto = '短い'; @author.save }.to raise_error }
      it { expect { @author.mailto = '111111@5464623'; @author.save }.to raise_error }
      it { expect { @author.mailto = '日本語.org'; @author.save }.to raise_error }
      it { expect { @author.mailto = 'e-mail@日本語.org'; @author.save }.to raise_error }
    end

    context '#crypted_password' do
      include_context 'authors reset'
      before { args_set(); @pass = create_sample_password('example', 'windows_linux_macosx', @salt = create_sample_salt) }
      subject { @author.crypted_password }

      it { should be_nil }
      it { expect { @author[:crypted_password] = nil; @author.save }.to change { [@author.crypted_password, @author.new?] }.from([nil, true]).to([nil, false]) }
      it { expect { @author[:crypted_password] = @pass; @author.save }.to change { [@author.crypted_password, @author.new?] }.from([nil, true]).to([@pass, false]) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:crypted_password => nil)) }.to_not raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:crypted_password => @pass)) }.to_not raise_error }
      it { expect { @author[:crypted_password] = ''; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = 'ab'; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = '短い'; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = @pass[0..-2]; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = @pass + 'a'; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = @pass.upcase; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = @pass[0..-2]; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = @pass + 'a'; @author.save }.to raise_error }
      it { expect { @author[:crypted_password] = '!' + @pass[1..-1]; @author.save }.to raise_error }
    end

    context '#password_salt' do
      include_context 'authors reset'
      before { args_set(); @pass = create_sample_password('foobarbaz', 'windows_linux_macosx', @salt = create_sample_salt) }
      subject { @author.password_salt }

      it { should be_nil }
      it { expect { @author[:password_salt] = nil; @author.save }.to change { [@author.password_salt, @author.new?] }.from([nil, true]).to([nil, false]) }
      it { expect { @author[:password_salt] = @salt; @author.save }.to change { [@author.password_salt, @author.new?] }.from([nil, true]).to([@salt, false]) }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:password_salt => nil)) }.to_not raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:password_salt => @salt)) }.to_not raise_error }
      it { expect { @author[:password_salt] = ''; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = 'ab'; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = '短い'; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = @salt[0..-2]; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = @salt + 'a'; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = @salt.upcase; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = @salt[0..-2]; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = @salt + 'a'; @author.save }.to raise_error }
      it { expect { @author[:password_salt] = '!' + @salt[1..-1]; @author.save }.to raise_error }
    end
  end
end

describe 'migration: 001_create_authors' do
  let(:database_migration_params) { {:target => 1} }
  context 'migration.up' do
    include_context 'Environment.setup'
    let(:require_models) { false }
    specify 'version is 1' do @database[:schema_info].first[:version].should == 1 end
    specify 'created authors' do @database.tables.should be_include(:authors) end
  end
  context 'migration.down' do
    include_context 'Environment.setup'
    let(:require_models) { false }
    before :all do database_demigrate(@database, 0) end

    specify 'dropped authors' do @database.tables.should_not be_include(:authors) end
  end
end
