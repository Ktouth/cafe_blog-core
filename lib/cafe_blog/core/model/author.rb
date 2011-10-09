require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 著者情報に対応するモデルクラス
      # @attr [Integer] id 筆者を識別する番号
      # @attr [String] code 筆者を識別するコード名。ログイン時のアカウント名および筆者による絞り込み時のディレクトリ名としても使用
      class Author < Core::Model(:authors)
      end
    end
  end
end