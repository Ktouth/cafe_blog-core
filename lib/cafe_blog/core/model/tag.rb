require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # タグ情報に対応するモデルクラス
      # @attr [Integer] id 筆者を識別する番号。新規作成時に自動設定される
      class Tag < Core::Model(:tags)
        restrict_primary_key
        set_operation_freeze_columns :id
      end
    end
  end
end