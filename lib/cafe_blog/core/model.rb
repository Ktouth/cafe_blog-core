module CafeBlog
  module Core
    # @author Keiichiro Nishi
    # Sequelモデルクラスに適用する、各種追加機能を提供するプラグインモジュール
    module ModelHelper
      # Sequelモデルクラスに適用するクラスメソッド群
      module ClassMethods
        # 登録後に値を変更してはいけないカラムを設定する。
        # このメソッドで指定したカラムは生成時のみ変更可で、登録後は値を変更しようとすると{ModelOperationError}例外を生成する
        # @param [Array] columns 設定したいカラム（もしくは多対一の関連)の名前の配列。カラム名は+Symbol+のみを受け付ける
        # @raise [ArgumentError] +Symbol+以外のカラム名もしくは存在しないカラム名、多対一以外の関連名を指定した
        def set_operation_freeze_columns(*columns)
          raise ArgumentError, '%sにカラム名として不適切なものが含まれています' % columns.inspect unless columns.all? {|x| x.is_a?(Symbol) }
          raise ArgumentError, '%sにカラム名として存在しないものが含まれています' % columns.inspect unless columns.all? {|x| self.columns.include?(x) || association_reflections[x] }
          columns = [primary_key, restricted_columns].flatten.compact if columns.empty?
          associations = columns.inject([]) do |r, x|
            unless self.columns.include?(x)
              raise ArgumentError, '%sに多対一以外の関連要素が含まれています' % columns.inspect unless association_reflections[x] && (association_reflections[x][:type] == :many_to_one)
              r.push x
            end
            r
          end
          columns.concat associations.map {|x| association_reflections[x][:key] } unless associations.empty?
          msg = 'is primary key or restricted columns.'
          columns.each do |sym|
            class_eval("def #{sym}=(value); new? ? super(value) : (raise ModelOperationError, '#{sym} #{msg}') end", __FILE__, __LINE__)
          end
          associations.each do |sym|
            getter = association_reflections[sym][:key].to_s
            get_model_bases.find_all {|x| x.instance_methods(false).include?(getter) }.each do |c|
              c.class_eval { protected getter }
            end
            class_eval { protected "#{getter}=" }
          end
        end

        # カラムの変更用メソッドを削除する、
        # モデル基底クラスに自動的に定義される変更用メソッドを削除する。モデルクラスで再定義した場合も含め全ての変更用メソッドを検索し削除する。変更用メソッドが無い場合は何もしない
        # @param [Array] columns 削除したいから無名の配列。カラム名は+Symbol+のみを受け付ける
        # @raise [ArgumentError] +Symbol+以外のカラム名もしくは存在しないカラム名を指定した
        def remove_column_setters(*columns)
          raise ArgumentError, 'カラム名が指定されていません' if columns.empty?
          raise ArgumentError, '%sにカラム名として不適切なものが含まれています' % columns.inspect unless columns.all? {|x| x.is_a?(Symbol) }
          raise ArgumentError, '%sにカラム名として存在しないものが含まれています' % columns.inspect unless columns.all? {|x| self.columns.include?(x) }

          columns.uniq.each do |sym|
            meth = "#{sym}="
            get_model_bases.find_all {|x| x.instance_methods(false).include?(meth) }.each do |c|
              c.class_eval { remove_method(meth) }
            end
          end
        end

        # モデルレコードにない追加カラムを定義する。
        # このメソッドで定義したカラムはデータベースに直接は反映されない。カラム値を変更すると+#modified?+の値が+true+になる
        # @param [Array] columns 削除したいから無名の配列。カラム名は+Symbol+のみを受け付ける
        # @raise [ArgumentError] +Symbol+以外のカラム名もしくは存在するカラム名を指定した
        def alt_column_accessors(*columns)
          raise ArgumentError, 'カラム名が指定されていません' if columns.empty?
          raise ArgumentError, '%sにカラム名として不適切なものが含まれています' % columns.inspect unless columns.all? {|x| x.is_a?(Symbol) }
          raise ArgumentError, '%sにカラム名として存在するものが含まれています' % columns.inspect if columns.any? {|x| self.columns.include?(x) }

          columns.each do |sym|
            attr_reader sym
            class_eval("def #{sym}=(value); unless @#{sym} == value; @#{sym} = value; modified! end; @#{sym} end", __FILE__, __LINE__)
          end
        end

        private

        def get_model_bases; ancestors[0 ... ancestors.index(Sequel::Model)] end
      end
    end
  end
end
