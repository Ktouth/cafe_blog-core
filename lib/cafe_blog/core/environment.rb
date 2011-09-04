# -*- encoding: UTF-8 -*-
require 'sequel'

module CafeBlog
  module Core
    # モデルデータなどのライブラリが利用する設定を保持するクラス
    class Environment
      class <<self
        private :new

        # 環境設定を行いモデルデータの利用を可能にする
        # @option opts [Sequel::Database] :database モデルデータの格納されるデータベースを指定します
        # @return [CafeBlog::Core::Environment] 設定を行った環境情報を返します
        # @raise [ArgumentError] Hash以外のパラメータが与えられました
        def setup(opts)
          raise ArgumentError, 'Hash以外のパラメータが与えられました' unless opts.is_a?(Hash)
          raise ArgumentError, 'データベースが指定されていません' unless opts[:database].is_a?(Sequel::Database)
          raise ApplicationError, '既に環境設定が行われています' if @instance
          @instance = new(opts)
        end
        
        # @return [Environment] 現在の環境設定を返します
        attr_reader :instance
      end

      # @private
      def initialize(opts)
      end
    end
  end
end
