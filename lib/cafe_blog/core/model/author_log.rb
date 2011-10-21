require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 筆者の行動および認証ログに関するモデルクラス
      # @attr [Integer] id ログを識別する番号
      # @attr_reader [Time] time ログの記録された時刻
      class AuthorLog < Core::Model(:author_logs)
        restrict_primary_key
        set_operation_freeze_columns
        remove_column_setters :time

        validates(:time) { presence }

        private

        def initialize_set(h)
          set(h)
          values[:time] = Time.now
        end
      end
    end
  end
end