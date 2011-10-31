$KCODE='u'

class String # :nodoc:
  instance_methods.include? 'humanize' or
  define_method(:humanize) { self.dup }
end

module NotNaughty # :nodoc:
  Validation.instance_eval { alias not_naughty_new new }
  def Validation.new(*args, &block) # :nodoc:
    if args.first.is_a?(Class) and args.first < self
      klass, opts = args[0], args[2]
      opts[:message] ||= klass.default_message(opts) if klass.respond_to?(:default_message)
    end
    not_naughty_new(*args, &block)
  end

  def AcceptanceValidation.default_message(opts); '#{"%s".humanize} は受け入れられませんでした。' end # :nodoc:
  def ConfirmationValidation.default_message(opts); '%s の確認が取れませんでした。' end # :nodoc:
  def FormatValidation.default_message(opts); '%s の書式が一致しませんでした。' end # :nodoc:
  def LengthValidation.default_message(opts) # :nodoc:
    if opts[:is] then "%s の長さが#{opts[:is]}ではありませんでした。"
    elsif opts[:within] then "%s の長さが#{opts[:within].min}～#{opts[:within].max}ではありませんでした。"
    elsif opts[:minimum] && opts[:maximum] then "%s の長さが#{opts[:minimum]}～#{opts[:maximum]}ではありませんでした。"
    elsif opts[:minimum] then "%s の長さが#{opts[:minimum]}未満でした。"
    elsif opts[:maximum] then "%s の長さが#{opts[:maximum]}を越えていました。"
    end
  end
  def NumericalityValidation.default_message(opts); opts[:only_integer] ? '%s は整数ではありませんでした。' : '%s は数値ではありませんでした。' end # :nodoc:
  def PresenceValidation.default_message(opts); '%s が設定されていませんでした。' end # :nodoc:
  
  def UniquenessValidation.default_message(opts); '%s の値が重複していました。' end # :nodoc:
end
