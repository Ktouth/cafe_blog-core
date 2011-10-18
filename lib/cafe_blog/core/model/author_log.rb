require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 筆者の行動および認証ログに関するモデルクラス
      # @attr [Integer] id ログを識別する番号
      class AuthorLog < Core::Model(:author_logs)
        restrict_primary_key
        set_operation_freeze_columns
      end
    end
  end
end