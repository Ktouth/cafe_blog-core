# -*- encoding: UTF-8 -*-
require 'sequel'

module CafeBlog
  module Core
    # モデルデータなどのライブラリが利用する設定を保持するクラス
    class Environment
      DefaultSaltSeed = 'this string used for password salt base-string.' # 既定の「パスワードｓａｌｔのベースとなる文字列」

      class <<self
        private :new

        # 環境設定を行いモデルデータの利用を可能にする
        # @option opts [Sequel::Database] :database モデルデータの格納されるデータベースを指定します
        # @option opts [boolean] :require モデルクラスの定義をロードするかどうかを指定します。デフォルトは+true+です
        # @option opts [String] :salt_seed パスワードを暗号化する際、saltの生成ベースとして使用する八文字以上の文字列を指定します。デフォルトは+DefaultSaltSeed+です
        # @return [CafeBlog::Core::Environment] 設定を行った環境情報を返します
        # @raise [ArgumentError] Hash以外のパラメータが与えられました
        # @raise [ArgumentError] データベースが指定されていません
        # @raise [ArgumentError] 既に環境設定が行われています
        # @raise [ArgumentError] +:salt_seed+ に無効な値が指定されています。八文字以上の文字列を指定して下さい
        def setup(opts)
          raise ArgumentError, 'Hash以外のパラメータが与えられました' unless opts.is_a?(Hash)
          raise ArgumentError, 'データベースが指定されていません' unless opts[:database].is_a?(Sequel::Database)
          raise ApplicationError, '既に環境設定が行われています' if @instance

          seed = opts.fetch(:salt_seed, DefaultSaltSeed)
          raise ArgumentError, ':salt_seed に無効な値が指定されています。八文字以上の文字列を指定して下さい' if !seed.is_a?(String) or seed.size < 8

          @instance = new(opts.merge(:salt_seed => seed))
          require_models if opts.fetch(:require, true)

          @instance
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

      # @return [Sequel::Database] モデルデータを保持するデータベースを返します
      attr_reader :database

      # @return [String] パスワードを暗号化する際、saltの生成ベースとして使用する文字列を返します
      attr_reader :salt_seed

      private

      def initialize(opts)
        @database = opts[:database]
        @salt_seed = opts[:salt_seed]
      end
    end
  end
end
