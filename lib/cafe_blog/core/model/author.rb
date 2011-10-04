require 'sequel/model'

module CafeBlog
  module Core
    module Model
      # 著者情報に対応するモデルクラス
      class Author < Core::Model(:authors)
        
      end
    end
  end
end