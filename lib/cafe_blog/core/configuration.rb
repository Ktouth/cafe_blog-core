require 'singleton'
require 'not_naughty'

module CafeBlog
  module Core
    # 環境情報保持クラス
    class Configuration
      extend NotNaughty
      class <<self
        # データベースに保持する際に使用する識別キー
        # @return [String] 識別キー
        attr_reader :key

        private
  
        def load_values
          if r = Environment.check_instance.database[:configurations].filter(:key => self.key).first
            r = Marshal.load(r[:values])
          else
            r = {}
          end
          sync_values(r)
        end

        def store_values
          db = Environment.check_instance.database
          values = Marshal.dump(sync_values(instance.instance_variable_get(:@values).dup))
          if db[:configurations].filter(:key => self.key).empty?
            db[:configurations].insert(:key => self.key, :values => values)
          else
            db[:configurations].filter(:key => self.key).update(:values => values)
          end
          self
        end

        def sync_values(hash)
          hash.delete_if {|k, v| !@initialize_values.include?(k) }
          @initialize_values.each do |k, v|
            hash[k] = v.is_a?(Proc) ? v.call : v unless hash.include?(k)
          end
          hash
        end        
      end

      # インスタンスを人間が読める形式に変換した文字列を返す
      # @return [String] 変換した文字列
      def inspect
        '#<%s @values=%s>' % [self.class.name, @values.inspect]
      end

      # このインスタンスの保持値が変更されたかどうかを返す
      # @return [Boolean] 変更されている時+true+を返す
      def modified?; @modified_p end

      # このインスタンスの保持値が変更されたことを明示的に指定する
      # @return [Configuration] このインスタンス自身を返す
      def modified!; @modified_p = true; self end

      private

      def initialize
        @values = self.class.send :load_values
        @modified_p = false
      end      
    end

    # 環境変数保持クラスのサブクラスを生成する
    # @param [String] key 保持のための使用される識別キー
    # @param [Hash] values データベースに保持される属性メソッドとその初期値のハッシュ
    # @return [Class] {Configuration}のサブクラス
    # @raise [ArgumentError] +key+が適切な文字列ではない
    # @raise [ArgumentError] +values+が適切なハッシュではない
    def self.Configuration(key, values)
      raise ArgumentError, "#{key.inspect}は適切な文字列ではありません" unless key.is_a?(String) && key =~ /^(?!\d)[a-z\d_]+$/
      raise ArgumentError, "#{values.class}は適切なハッシュではありません" unless values.is_a?(Hash)

      Class.new(Configuration).tap do |c|
        c.instance_variable_set(:@key, key)
        c.instance_variable_set(:@initialize_values, values)
        values.each do |sym, val|
          c.module_eval("def #{sym}; @values[#{sym.inspect}] end", __FILE__, __LINE__)
          c.module_eval("def #{sym}=(value); unless @values[#{sym.inspect}] == value then; @values[#{sym.inspect}] = value; @modified_p = true end; end", __FILE__, __LINE__)
        end
        c.module_eval { include Singleton }
      end
    end
  end
end