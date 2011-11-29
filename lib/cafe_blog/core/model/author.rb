require 'sequel/model'
require 'digest/sha1'

module CafeBlog
  module Core
    module Model
      # 著者情報に対応するモデルクラス
      # @attr [Integer] id 筆者を識別する番号。新規作成時に自動設定される
      # @attr [String] code 筆者を識別するコード名。新規作成時のみ設定可能。ログイン時のアカウント名および筆者による絞り込み時のディレクトリ名としても使用
      #   筆者コードは3字以上16字以内で先頭が英子文字で始まる英小文字と数字およびアンダーバーのみで構成されているもののみを受け付ける
      # @attr [String] name 筆者名。一意的なもののみを受け付ける
      # @attr [String] mailto 筆者への連絡用メールアドレス。連絡不要の場合は +nil+ を受け付ける
      # @attr_reader [String] crypted_password 暗号化された筆者のログイン用パスワード
      # @attr_reader [String] password_salt パスワード照会用のsaltコード
      # @attr [String] password パスワード変更時に新規パスワードを設定する。通常時および保存完了後は+nil+を返す
      # @attr [String] password_confirmation パスワード変更時に新規パスワード(確認のため)を設定する。通常時および保存完了後は+nil+を返す
      # @attr [TrueClass] loginable 認証機能においてログイン可能かどうかを取得または設定する。規定値は+true+
      # @attr [TrueClass] enable 筆者情報として有効かどうかを取得または設定する。規定値は+true+
      class Author < Core::Model(:authors)
        restrict_primary_key
        set_operation_freeze_columns :id, :code
        remove_column_setters :crypted_password, :password_salt
        alt_column_accessors :password, :password_confirmation

        validates(:code) { presence and uniqueness and length(:minimum => 3, :maximum => 16) and format(:with => /^(?![_\d])[a-z\d_]+$/) }
        validates(:name) { presence and uniqueness }
        validates(:mailto) { format(:with => :email, :allow_nil => true) }
        validates(:crypted_password) { length(:is => 40, :allow_nil => true) and format(:with => /^[\da-f]{40}$/, :allow_nil => true) }
        validates(:password_salt) { length(:is => 40, :allow_nil => true) and format(:with => /^[\da-f]{40}$/, :allow_nil => true) }
        validates(:password) { format(:with => /^(?![a-z]+$|[A-Z]+$|\d+$)[A-Za-z\d]{8,40}$/, :allow_nil => true) and confirmation(:allow_nil => true) }

        class <<self
          # 筆者コードとパスワードを元に認証処理を行う
          # @param [String] code 認証したい筆者の識別コード
          # @param [String] password 認証用のパスワード
          # @return [Author] 認証に成功した場合は対応する筆者情報を返す。該当する筆者がいない、無効になっている、ログイン権限がない、パスワードが間違っている、および不正な引数を渡された場合は+nil+を返す
          # @note ログインの成功・失敗・拒否はログとして記録される。パスワードを1日以内に5回以上間違えると、以降のログインを拒否する。
          def authentication(code, password)
            if code.is_a?(String) and password.is_a?(String) and author = query[:code => code]
              check = Digest::SHA1.hexdigest([author.code, password, author.password_salt].join(':')) == author.crypted_password
              flag = author.enable && author.loginable && !!author.crypted_password
              if flag and check
                AuthorLog.create(:author => author, :action => 'login', :detail => ('login successed.[agent: %s]' % Environment.get_agent))
                return author
              elsif flag
                AuthorLog.create(:author => author, :action => 'login.failed', :detail => ('invalid password.[pass: %s][agent: %s]' % [password, Environment.get_agent]))
                if get_logs_count(author) >= 5
                  Author.dataset.filter(:id => author.id).update(:loginable => false)
                  author.reload
                  AuthorLog.create(:author => author, :action => 'login.rejected', :detail => ('too much login failure.[author: %s][agent: %s]' % [author.code, Environment.get_agent]))
                end
              elsif check
                AuthorLog.create(:author => author, :action => 'login.rejected', :detail => ('author can\'t login.[author: %s][agent: %s]' % [author.code, Environment.get_agent]))
              else
                AuthorLog.create(:author => author, :action => 'login.failed', :detail => ('invalid password.[pass: %s][agent: %s]' % [password, Environment.get_agent]))
              end
            else
              AuthorLog.create(:author => nil, :action => 'login.failed', :detail => ('code is not found.[code: %s][pass: %s][agent: %s]' % [code, password, Environment.get_agent]))
            end
            nil
          end

          private

          def get_logs_count(author, limit = 24)
            _tm = Time.now - 3600 * limit
            AuthorLog.filter(:author => author, :action => 'login.failed').filter { time >= _tm }.count
          end
        end

        # 適切な指定を行ったクエリを取得する
        # @method query
        # @return [Sequel::Dataset] {Author}モデルのクエリを返す。クエリには無効な筆者情報は含まない
        subset(:query, :enable => true)

        private

        def initialize_set(h)
          set({:loginable => true, :enable => true}.merge(h))
        end

        def before_save
          if password
            self[:password_salt] = CafeBlog::Core::Environment.check_instance.generate_salt
            self[:crypted_password] = Digest::SHA1.hexdigest([code, password, password_salt].join(':'))
          end
          [:@password, :@password_confirmation].each {|sym| remove_instance_variable(sym) rescue nil }
          super 
        end
        
        def after_create
          super
          AuthorLog.create(:author => self, :action => 'author.create', :detail => 'created author.[code: %s][name: %s][agent: %s]' % [code, name, Environment.get_agent])
        end
        def after_update
          super
          AuthorLog.create(:author => self, :action => 'author.update', :detail => 'updated author.[code: %s][name: %s][agent: %s]' % [code, name, Environment.get_agent])
        end
        def after_destroy
          super
          AuthorLog.create(:author => nil, :action => 'author.delete', :detail => 'deleted author.[id: %d][code: %s][name: %s][agent :%s]' % [id, code, name, Environment.get_agent])
        end
      end
    end
  end
end