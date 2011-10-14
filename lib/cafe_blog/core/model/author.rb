require 'sequel/model'
require 'digest/sha1'

module CafeBlog
  module Core
    module Model
      # 著者情報に対応するモデルクラス
      # @attr [Integer] id 筆者を識別する番号
      # @attr [String] code 筆者を識別するコード名。ログイン時のアカウント名および筆者による絞り込み時のディレクトリ名としても使用、既存のレコードのcodeは変更出来ない
      #   筆者コードは3字以上16字以内で先頭が英子文字で始まる英小文字と数字およびアンダーバーのみで構成されているもののみを受け付ける
      # @attr [String] name 筆者名。一意的な三文字以上のもののみを受け付ける
      # @attr [String] mailto 筆者への連絡用メールアドレス。連絡不要の場合は +nil+ を受け付ける
      # @attr_reader [String] crypted_password 暗号化された筆者のログイン用パスワード
      # @attr_reader [String] password_salt パスワード紹介用のsaltコード
      # @attr [String] password パスワード変更時に新規パスワードを設定する。通常時および保存完了後は+nil+を返す
      # @attr [String] password_confirmation パスワード変更時に新規パスワード(確認のため)を設定する。通常時および保存完了後は+nil+を返す
      class Author < Core::Model(:authors)
        restrict_primary_key
        set_restricted_columns :code
        [primary_key, restricted_columns].flatten.each do |sym|
          class_eval(<<-ENDE, __FILE__, __LINE__)
            def #{sym}=(value)
              if new?
                self[:#{sym}] = value
              else
                raise ModelOperationError, '#{sym} is primary key or restricted columns.'
              end
            end
          ENDE
        end
        [:crypted_password, :password_salt].each do |sym|
          meth = "#{sym}="
          ancestors.each do |c|
            raise ArgumentError, 'method[ %s ] is not found.' % meth if c == Sequel::Model
            if c.instance_methods(false).include?(meth)
              c.class_eval { remove_method(meth) }
              break
            end
          end
        end
        [:password, :password_confirmation].each do |sym|
          attr_reader sym
          class_eval("def #{sym}=(value); unless @#{sym} == value; @#{sym} = value; modified! end; @#{sym} end", __FILE__, __LINE__)
        end

        validates(:code) { presence and uniqueness and length(:minimum => 3, :maximum => 16) and format(:with => /^(?![_\d])[a-z\d_]+$/) }
        validates(:name) { presence and uniqueness and length(:minimum => 3) and format(:with => /^.{3,}$/u) }
        validates(:mailto) { format(:with => :email, :allow_nil => true) }
        validates(:crypted_password) { length(:is => 40, :allow_nil => true) and format(:with => /^[\da-f]{40}$/, :allow_nil => true) }
        validates(:password_salt) { length(:is => 40, :allow_nil => true) and format(:with => /^[\da-f]{40}$/, :allow_nil => true) }
        validates(:password) { format(:with => /^(?![a-z]+$|[A-Z]+$|\d+$)[A-Za-z\d]{8,40}$/, :allow_nil => true) and confirmation(:allow_nil => true) }

        class <<self
          # 筆者コードとパスワードを元に認証処理を行う
          # @param [String] code 認証したい筆者の識別コード
          # @param [String] password 認証用のパスワード
          # @return [Author] 認証に成功した場合は対応する筆者情報を返す。該当する筆者がいない、パスワードが間違っている、不正な引数を渡された場合は+nil+を返す
          def authentication(code, password)
            if code.is_a?(String) and password.is_a?(String) and author = filter(:code => code).first
              return author if Digest::SHA1.hexdigest([author.code, password, author.password_salt].join(':')) == author.crypted_password
            end
            nil
          end
        end

        private

        def before_save
          if password
            self[:password_salt] = CafeBlog::Core::Environment.check_instance.generate_salt
            self[:crypted_password] = Digest::SHA1.hexdigest([code, password, password_salt].join(':'))
          end
          [:@password, :@password_confirmation].each {|sym| remove_instance_variable(sym) rescue nil }
          super 
        end
      end
    end
  end
end