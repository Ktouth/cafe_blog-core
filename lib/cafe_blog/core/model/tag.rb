require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # タグ情報に対応するモデルクラス
      # @attr [Integer] id タグを識別する番号。新規作成時に自動設定される
      # @attr [String] name タグ名。一意的なもののみを受け付ける
      # @attr [String] code タグを識別するコード名。省略可。 #to_code を参照。タグによる絞り込みやURLなどで使用
      # @attr [Tag] group タグが所属する大分類タグ。大分類タグ自身の時は+nil+となる。
      #   タグコードは3字以上16字以内で先頭が英子文字で始まる英小文字と数字およびアンダーバーのみで構成されているもののみを受け付ける
      class Tag < Core::Model(:tags)
        many_to_one :group, :class => self

        restrict_primary_key
        set_operation_freeze_columns :id
        protected_foreign_keys

        validates(:name) { presence and uniqueness }
        validates(:code, :allow_nil => true) { uniqueness and length(:minimum => 3, :maximum => 16) and format(:with => /^(?![_\d])[a-z\d_]+$/) }

        # タグに対応するコードを取得する
        # @note #code が設定されている時はそれが、設定されていない既存タグは 'tag%04d' % #id が、#code が設定されてない新規タグは 'tag0000' を返す
        # @return [String] タグコード
        def to_code
          code || ('tag%04d' % (id || 0))
        end
      end
    end
  end
end