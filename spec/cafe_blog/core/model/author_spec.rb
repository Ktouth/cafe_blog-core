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
  
  context '.columns' do
    subject { CafeBlog::Core::Model::Author.columns }
    it { should_not include(:password) }
    it { should_not include(:password_confirmation) }
  end

  context '.authentication' do
    before :all do
      @model = CafeBlog::Core::Model::Author
      @admin = @model[1]
      @password = ExampleDBAuthorsPassword[@admin.code][:password]
      @user = @model.filter(:code => 'example').first
      @user_password = ExampleDBAuthorsPassword[@user.code][:password]
    end
    before { @result = nil }
    it { should respond_to(:authentication) }
    it { expect { @model.authentication }.to raise_error(ArgumentError) }
    it { expect { @model.authentication('test') }.to raise_error(ArgumentError) }
    it { expect { @model.authentication('windows', 'linux', 'max_osx') }.to raise_error(ArgumentError) }
    it { expect { @model.authentication(@admin.code, @password) }.to_not raise_error }
    it { expect { @model.authentication('no-code', 'invalid password') }.to_not raise_error }
    it { expect { @model.authentication(:bad_type, /invalid password/) }.to_not raise_error }
    it { expect { @result = @model.authentication(@admin.code, @password) }.to change { @result ? @result.code : nil }.from(nil).to(@admin.code) }
    it { expect { @result = @model.authentication(@user.code, @user_password) }.to change { @result ? @result.code : nil }.from(nil).to(@user.code) }
    it { expect { @result = @model.authentication(@admin.code, @user_password) }.to_not change { @result ? @result.code : nil }.from(nil).to(@admin.code) }
    it { expect { @result = @model.authentication(@admin.code, '') }.to_not change { @result ? @result.code : nil }.from(nil).to(@admin.code) }
    it { expect { @result = @model.authentication(@admin.code, @password.upcase) }.to_not change { @result ? @result.code : nil }.from(nil).to(@admin.code) }
    it { expect { @result = @model.authentication(/invalid/, @user_password) }.to_not change { @result ? @result.code : nil }.from(nil).to(@user.code) }
    it { expect { @result = @model.authentication(CafeBlog::Core::Model::Author[2].code, @user_password) }.to_not change { @result ? @result.code : nil }.from(nil).to(@user.code) }
    context 'crypt operetion check' do
      before do
        key = '%s:%s:%s' % [@admin.code, @password, @admin.password_salt]
        crypted = create_sample_password(@admin.code, @password, @admin.password_salt)
        Digest::SHA1.should_receive(:hexdigest).with(key).once.and_return { crypted }
      end
      it { expect { @result = @model.authentication(@admin.code, @password) }.to change { @result ? @result.code : nil }.from(nil).to(@admin.code) }
    end
    context 'not loginable check' do
      before do
        @not_loginable = @model.filter(:loginable => false).first
        @not_loginable_password = ExampleDBAuthorsPassword[@not_loginable.code][:password]
        @disable = @model.filter(:enable => false).exclude(:crypted_password => nil).first
        @disable_password = ExampleDBAuthorsPassword[@disable.code][:password]
      end
      it { expect { @result = @model.authentication(@not_loginable.code, @not_loginable_password) }.to_not change { @result ? @result.code : nil } }
      it { expect { @result = @model.authentication(@disable.code, @disable_password) }.to_not change { @result ? @result.code : nil } }
    end
  end
  
  describe '.query' do
    subject { CafeBlog::Core::Model::Author.query }
    it { should be_a(Sequel::Dataset) }
    it { subject.all? {|x| x.is_a?(CafeBlog::Core::Model::Author) }.should be_true }
    it { subject.all? {|x| x.enable }.should be_true }
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
    it { should respond_to(:password) }
    it { should respond_to(:password_confirmation) }
    it { should respond_to(:loginable) }
    it { should respond_to(:enable) }

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

    def set_password(author, pass, confirm)
      author.password = pass
      author.password_confirmation = confirm
    end

    context '#password' do
      include_context 'authors reset'
      before { args_set(); @pass = 'examPLE18523Afafd' }
      subject { @author.password }
      
      it { should be_nil }
      it { should == @author.password_confirmation }
      context do
        subject { @admin.password }
        it { should be_nil }
        it { should == @admin.password_confirmation }
      end
        
      it { expect { set_password(@author, nil, nil); @author.save }.to_not change { subject } }
      it { expect { set_password(@author, @pass, @pass); @author.save }.to_not change { subject } }
      it { expect { m = ''; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = '123adfd'; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = 'oRs12x' * 8; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = 'oRs日本語は通らない12x'; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = 115312; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = /regexp/; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = 'aaaaaaaabbbbbbbb'; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = '1234567890'; set_pasword(@author, m, m); @author.save }.to raise_error }
      it { expect { m = 'FASDFASD'; set_pasword(@author, m, m); @author.save }.to raise_error }
    end
    context '#password_confirmation' do
      include_context 'authors reset'
      before { args_set(); @pass = 'examPLE18523Afafd' }
      subject { @author.password_confirmation }
      
      it { should be_nil }
      it { should == @author.password }
      context do
        subject { @admin.password_confirmation }
        it { should be_nil }
        it { should == @admin.password }
      end
        
      it { expect { set_password(@author, nil, nil); @author.save }.to_not change { subject } }
      it { expect { set_password(@author, @pass, @pass); @author.save }.to_not change { subject } }
    end
    
    describe 'operation: password change' do
      include_context 'authors reset'
      shared_context('set digest mock') do
        let(:new_password) { 'invalidPassword' }
        before do
          @salt = create_sample_salt
          _key = [subject.code, new_password, @salt].join(':')
          @crypted = _crypted = Digest::SHA1.hexdigest(_key)
          CafeBlog::Core::Environment.instance.should_receive(:generate_salt).ordered.and_return { @salt }
          Digest::SHA1.should_receive(:hexdigest).with(_key).ordered.and_return { @crypted }
        end
      end
      shared_context('set no digest mock') do
        before do
          CafeBlog::Core::Environment.instance.should_not_receive(:generate_salt).with(no_args)
          Digest::SHA1.should_not_receive(:hexdigest).with(String)
        end
      end
      before do
        @pass = 'thisISpass123789Ok'
      end

      context 'new item' do
        before { args_set() }
        subject { @author }
        it { expect { set_password(subject, @pass, @pass); subject.save }.to_not raise_error }
        it { expect { set_password(subject, @pass, @pass); subject.save }.to_not change { subject.password } }
        it { expect { set_password(subject, @pass, @pass); subject.save }.to_not change { subject.password_confirmation } }
        context 'changed password' do
          include_context 'set digest mock'
          let(:new_password) { @pass }
          it { expect { set_password(subject, @pass, @pass); subject.save }.to change { subject.crypted_password }.to(@crypted) }
          it { expect { set_password(subject, @pass, @pass); subject.save }.to change { subject.password_salt }.to(@salt) }
        end
        context 'no changed password' do
          include_context 'set no digest mock'
          it { expect { set_password(subject, nil, nil); subject.save }.to_not raise_error }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.password } }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.password_confirmation } }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.crypted_password } }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.password_salt } }
        end
        context 'invalid password confirmation' do
          it { expect { set_password(subject, @pass, nil); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, ''); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, 123); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, /ssssssssssssssss123456/); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, @pass.to_sym); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, @pass[0..-2]); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, @pass.upcase); subject.save }.to raise_error(Sequel::ValidationFailed) }
        end
      end
      context 'already exist item' do
        subject { @admin }
        it { expect { set_password(subject, @pass, @pass); subject.save }.to_not raise_error }
        it { expect { set_password(subject, @pass, @pass); subject.save }.to_not change { subject.password } }
        it { expect { set_password(subject, @pass, @pass); subject.save }.to_not change { subject.password_confirmation } }
        context 'changed password' do
          include_context 'set digest mock'
          let(:new_password) { @pass }
          it { expect { set_password(subject, @pass, @pass); subject.save }.to change { subject.crypted_password }.to(@crypted) }
          it { expect { set_password(subject, @pass, @pass); subject.save }.to change { subject.password_salt }.to(@salt) }
        end
        context 'no changed password' do
          include_context 'set no digest mock'
          it { expect { set_password(subject, nil, nil); subject.save }.to_not raise_error }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.password } }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.password_confirmation } }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.crypted_password } }
          it { expect { set_password(subject, nil, nil); subject.save }.to_not change { subject.password_salt } }
        end
        context 'invalid password confirmation' do
          it { expect { set_password(subject, @pass, nil); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, ''); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, 123); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, /ssssssssssssssss123456/); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, @pass.to_sym); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, @pass[0..-2]); subject.save }.to raise_error(Sequel::ValidationFailed) }
          it { expect { set_password(subject, @pass, @pass.upcase); subject.save }.to raise_error(Sequel::ValidationFailed) }
        end
      end
    end

    context '#loginable' do
      include_context 'authors reset'
      before { args_set(:loginable); @invalid = CafeBlog::Core::Model::Author[5] }
      subject { @author.loginable }

      it { should be_true }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:loginable => nil)) }.to raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:loginable => true)) }.to_not raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:loginable => false)) }.to_not raise_error }
      it { expect { @author.loginable = true; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.loginable = false; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([false, false]) }
      it { expect { @invalid.loginable = true; @invalid.save }.to change { [@invalid.loginable, @invalid.new?] }.from([false, false]).to([true, false]) }
      it { expect { @author.loginable = nil; @author.save }.to raise_error }
      it { expect { @author.loginable = ''; @author.save }.to raise_error }
      it { expect { @author.loginable = 'abcde'; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.loginable = 1234589; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.loginable = /regexp/; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.loginable = '日本語'; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.loginable = :email; @author.save }.to change { [@author.loginable, @author.new?] }.from([true, true]).to([true, false]) }
    end

    context '#enable' do
      include_context 'authors reset'
      before { args_set(:enable); @invalid = CafeBlog::Core::Model::Author[6] }
      subject { @author.enable }

      it { should be_true }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:enable => nil)) }.to raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:enable => true)) }.to_not raise_error }
      it { expect { CafeBlog::Core::Model::Author.insert(valid_args(:enable => false)) }.to_not raise_error }
      it { expect { @author.enable = true; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.enable = false; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([false, false]) }
      it { expect { @invalid.enable = true; @invalid.save }.to change { [@invalid.enable, @invalid.new?] }.from([false, false]).to([true, false]) }
      it { expect { @author.enable = nil; @author.save }.to raise_error }
      it { expect { @author.enable = ''; @author.save }.to raise_error }
      it { expect { @author.enable = 'abcde'; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.enable = 1234589; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.enable = /regexp/; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.enable = '日本語'; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([true, false]) }
      it { expect { @author.enable = :email; @author.save }.to change { [@author.enable, @author.new?] }.from([true, true]).to([true, false]) }
    end
  end
end

describe 'migration: 001_create_authors' do
  context 'migration.up' do
    include_context 'Environment.setup'
    let(:database_migration_params) { {:target => 1} }
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
