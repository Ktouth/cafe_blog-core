require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 筆者の行動および認証ログに関するモデルクラス
      # @attr [Integer] id ログを識別する番号
      class AuthorLog < Core::Model(:author_logs)
        restrict_primary_key
        #set_restricted_columns :code
        [primary_key, restricted_columns].flatten.compact.each do |sym|
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
      end
    end
  end
end