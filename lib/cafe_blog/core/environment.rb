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

        # 環境変数が既に設定されているかを判断した上で現在の環境設定を返します。
        # @return [Environment] 現在の環境設定を返します
        # @raise [CafeBlog::Core::ApplicationError] 環境変数の設定が終わっていません
        def check_instance
          raise ApplicationError, '環境変数の設定が終わっていません' unless instance
          instance
        end

        private
  
        # @private
        def require_models
          Dir.glob(File.expand_path('../model/*.{rb,so,o,dll}', __FILE__)) {|file| require 'cafe_blog/core/model/%s' % File.basename(file, '.*') } 
        end
      end

      # @private
      def initialize(opts)
        @database = opts[:database]
      end

      # @return [Sequel::Database] モデルデータを保持するデータベースを返します
      attr_reader :database
    end
  end
end
