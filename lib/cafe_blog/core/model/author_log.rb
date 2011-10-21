require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 筆者の行動および認証ログに関するモデルクラス
      # @attr [Integer] id ログを識別する番号
      # @attr_reader [Time] time ログの記録された時刻
      # @attr_reader [String] host アクセス元のホスト名
      class AuthorLog < Core::Model(:author_logs)
        restrict_primary_key
        set_operation_freeze_columns
        remove_column_setters :time, :host

        validates(:time) { presence }
        validates(:host) { presence and format :with => %r!^[\-\_\.\!~\*'\(\)a-zA-Z0-9\;\?\@\&\=\+\$\,%#]+$! }

        private

        def initialize_set(h)
          values.merge!(:time => Time.now, :host => Environment.get_host_address)
          set(h)
        end
      end
    end
  end
end