require 'singleton'

module CafeBlog
  module Core
    # 環境情報保持クラス
    class Configuration
      class <<self
        # データベースに保持する際に使用する識別キー
        attr_reader :key

        private
  
        def load_values
          if r = Environment.check_instance.database[:configurations].filter(:key => self.key).first
            r = Marshal.load(r[:values])
          else
            r = {}
          end
          r.delete_if {|k, v| !@initialize_values.include?(k) }
          @initialize_values.each do |k, v|
            r[k] = v.is_a?(Proc) ? v.call : v unless r.include?(k)
          end
          r       
        end
      end

      # インスタンスを人間が読める形式に変換した文字列を返す
      # @return [String] 変換した文字列
      def inspect
        '#<%s @values=%s>' % [self.class.name, @values.inspect]
      end

      private

      def initialize
        @values = self.class.instance_variable_get(:@initialize_values).inject({}) do |r, (k, v)|
          case v
          when Proc
            r[k] = v.call
          else
            r[k] = v
          end
          r
        end
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
          c.module_eval("def #{sym}; @values[#{sym.inspect}] end")
          c.module_eval("def #{sym}=(value); @values[#{sym.inspect}] = value end")
        end
        c.module_eval { include Singleton }
      end
    end
  end
end