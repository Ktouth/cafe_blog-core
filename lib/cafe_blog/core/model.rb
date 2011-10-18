module CafeBlog
  module Core
    # @author Keiichiro Nishi
    # Sequelモデルクラスに適用する、各種追加機能を提供するプラグインモジュール
    module ModelHelper
      # Sequelモデルクラスに適用するクラスメソッド群
      module ClassMethods
        # 登録後に値を変更してはいけないカラムを設定する
        #   このメソッドで指定したカラムは生成時のみ変更可で、登録後は値を変更しようとすると{ModelOperationError}例外を生成する
        # @param [Array] columns 設定したいカラム名の配列。カラム名は{Symbol}のみを受け付ける
        # @raise [ArgumentError] Symbol以外のカラム名もしくは存在しないカラム名を指定した
        def set_operation_freeze_columns(*columns)
          raise ArgumentError, '%sにカラム名として不適切なものが含まれています' % columns.inspect unless columns.all? {|x| x.is_a?(Symbol) }
          raise ArgumentError, '%sにカラム名として存在しないものが含まれています' % columns.inspect unless columns.all? {|x| self.columns.include?(x) }
          columns = [primary_key, restricted_columns].flatten.compact if columns.empty?
          msg = 'is primary key or restricted columns.'
          columns.each do |sym|
            class_eval("def #{sym}=(value); new? ? self[:#{sym}] = value : (raise ModelOperationError, '#{sym} #{msg}') end", __FILE__, __LINE__)
          end
        end
      end
    end
  end
end
