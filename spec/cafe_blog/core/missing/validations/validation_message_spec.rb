require File.expand_path(File.dirname(__FILE__) + '/../../../../spec_helper')

describe NotNaughty::Validation do
  before :all do
    @class = Struct.new(:a, :b, :b_confirmation, :c, :d1, :d2, :d3, :d4, :d5, :e1, :e2, :f) do
      extend NotNaughty
      validates(:a) { acceptance }
      validates(:b) { confirmation }
      validates(:c) { format :with => /^[a-z]+$/ }
      validates(:d1) { length :is => 5 }
      validates(:d2) { length :within => 3..10 }
      validates(:d3) { length :minimum => 3, :maximum => 10 }
      validates(:d4) { length :minimum => 3 }
      validates(:d5) { length :maximum => 10 }
      validates(:e1) { numericality :only_integer => true }
      validates(:e2) { numericality }
      validates(:f) { presence }
    end
  end
  before { @item = @class.new('1', 'ok', 'ok', 'aaa', '12345', '12345', '12345', '12345', '12345', '+1234', '+1234.56', true) }
  specify { @item.valid?.should be_true }

  context '::AcceptanceValidation' do
    it { expect { @item.a = 'false' }.to change { @item.valid? }.to(false) }
    it { expect { @item.a = 'false'; @item.valid? }.to change { @item.errors.on(:a).join }.from('').to('a は受け入れられませんでした。') }
  end

  context '::ConfirmationValidation' do
    it { expect { @item.b = 'false'; @item.b_confirmation = 'true' }.to change { @item.valid? }.to(false) }
    it { expect { @item.b = 'false'; @item.b_confirmation = 'true'; @item.valid? }.to change { @item.errors.on(:b).join }.from('').to('b の確認が取れませんでした。') }
  end

  context '::FormatValidation' do
    it { expect { @item.c = '123456' }.to change { @item.valid? }.to(false) }
    it { expect { @item.c = '123456'; @item.valid? }.to change { @item.errors.on(:c).join }.from('').to('c の書式が一致しませんでした。') }
  end

  context '::LengthValidation' do
    it { expect { @item.d1 = '01234567890123456789' }.to change { @item.valid? }.to(false) }
    it { expect { @item.d1 = '01234567890123456789'; @item.valid? }.to change { @item.errors.on(:d1).join }.from('').to('d1 の長さが5ではありませんでした。') }
    it { expect { @item.d2 = '01234567890123456789' }.to change { @item.valid? }.to(false) }
    it { expect { @item.d2 = '01234567890123456789'; @item.valid? }.to change { @item.errors.on(:d2).join }.from('').to('d2 の長さが3～10ではありませんでした。') }
    it { expect { @item.d3 = '01234567890123456789' }.to change { @item.valid? }.to(false) }
    it { expect { @item.d3 = '01234567890123456789'; @item.valid? }.to change { @item.errors.on(:d3).join }.from('').to('d3 の長さが3～10ではありませんでした。') }
    it { expect { @item.d4 = '01' }.to change { @item.valid? }.to(false) }
    it { expect { @item.d4 = '01'; @item.valid? }.to change { @item.errors.on(:d4).join }.from('').to('d4 の長さが3未満でした。') }
    it { expect { @item.d5 = '01234567890123456789' }.to change { @item.valid? }.to(false) }
    it { expect { @item.d5 = '01234567890123456789'; @item.valid? }.to change { @item.errors.on(:d5).join }.from('').to('d5 の長さが10を越えていました。') }
  end

  context '::NumericalityValidation' do
    it { expect { @item.e1 = '-152.55' }.to change { @item.valid? }.to(false) }
    it { expect { @item.e1 = '-152.55'; @item.valid? }.to change { @item.errors.on(:e1).join }.from('').to('e1 は整数ではありませんでした。') }
    it { expect { @item.e2 = 'false' }.to change { @item.valid? }.to(false) }
    it { expect { @item.e2 = 'false'; @item.valid? }.to change { @item.errors.on(:e2).join }.from('').to('e2 は数値ではありませんでした。') }
  end

  context '::PresenceValidation' do
    it { expect { @item.f = nil }.to change { @item.valid? }.to(false) }
    it { expect { @item.f = nil; @item.valid? }.to change { @item.errors.on(:f).join }.from('').to('f が設定されていませんでした。') }
  end
end

describe 'String#humanize' do
  it { expect { eval("ActiveSupport::Inflector") }.to raise_error(NameError) }
  it { expect { 'sample'.humanize }.to_not raise_error(NoMethodError) }
  it { expect { 'sample'.humanize }.to_not raise_error(ArgumentError) }
end
