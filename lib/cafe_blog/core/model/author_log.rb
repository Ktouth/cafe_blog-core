require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 筆者の行動および認証ログに関するモデルクラス
      # @attr_reader [Integer] id ログを識別する番号。新規作成時のみ設定可能
      # @attr_reader [Time] time ログの記録された時刻
      # @attr_reader [String] host アクセス元のホスト名
      # @attr [Author] author ログの対象となる筆者情報。ログイン失敗などの筆者情報が不明のものは+nil+となる。新規作成時のみ設定可能
      # @attr [String] action 筆者の行動。新規作成時のみ設定可能。+login+・+post.article+などの英子文字のみの1単語もしくはドットで区切った2単語が設定可能
      class AuthorLog < Core::Model(:author_logs)
        many_to_one :author

        restrict_primary_key
        set_operation_freeze_columns :id, :author, :action
        remove_column_setters :time, :host

        validates(:time) { presence }
        validates(:host) { presence and format :with => %r!^[\-\_\.\!~\*'\(\)a-zA-Z0-9\;\?\@\&\=\+\$\,%#]+$! }
        validates(:action) { presence and format :with => %r!^[a-z]+(?:\.[a-z]+)?$! }

        private

        def initialize_set(h)
          values.merge!(:time => Time.now, :host => Environment.get_host_address)
          set(h)
        end
      end
    end
  end
end