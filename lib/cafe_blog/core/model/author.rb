require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 著者情報に対応するモデルクラス
      # @attr [Integer] id 筆者を識別する番号
      class Author < Core::Model(:authors)
      end
    end
  end
end