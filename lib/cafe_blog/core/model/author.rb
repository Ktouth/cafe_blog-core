require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 著者情報に対応するモデルクラス
      # @attr [Integer] id 筆者を識別する番号
      # @attr [String] code 筆者を識別するコード名。ログイン時のアカウント名および筆者による絞り込み時のディレクトリ名としても使用
      #   筆者コードは3字以上16字以内で先頭が英子文字で始まる英小文字と数字およびアンダーバーのみで構成されているもののみを受け付ける
      # @attr [String] name 筆者名。一意的な三文字以上のもののみを受け付ける
      class Author < Core::Model(:authors)
        validates(:code) { presence and uniqueness and length :minimum => 3, :maximum => 16 }
        validates(:code) { format :with => /^(?![_\d])[a-z\d_]+$/ }
        validates(:name) { presence and uniqueness and length :minimum => 3 }
        validates(:name) { format :with => /^.{3,}$/u }
      end
    end
  end
end