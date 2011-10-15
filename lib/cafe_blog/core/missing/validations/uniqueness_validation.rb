# @private
# @note sequel_notnaughty gem が提供する UniquenessValidation クラスのパッチコード
# @author K.Ktouth
module NotNaughty # :nodoc:
  class UniquenessValidation # :nodoc:
    private

    def initialize(valid, attributes)
      valid[:message] ||= '%s is already taken.'
      valid[:in] = case valid[:in]
      when Array; valid[:in].map { |scp| scp.to_sym }
      when String, String; [ valid[:in].to_sym ]
      else
        []
      end

      if valid[:allow_blank] or valid[:allow_nil]
        valid[:allow] = valid[:allow_blank] ? :blank? : :nil?

        super valid, attributes do |obj, attr, value|
          scope_values = obj.values.values_at(*valid[:in])
          scope = Hash[*valid[:in].zip(scope_values).flatten]

          value.send valid[:allow] or
          #obj.model.find(scope.merge(attr => value)).nil? or
          (obj.new? ? obj.model : obj.model.exclude(obj.pk_hash)).filter(scope.merge(attr => value)).empty? or
          obj.errors.add attr, valid[:message]
        end
      else

        super valid, attributes do |obj, attr, value|
          scope_values = obj.values.values_at(*valid[:in])
          scope = Hash[*valid[:in].zip(scope_values).flatten]

          #obj.model.find(scope.merge(attr => value)).nil? or
          (obj.new? ? obj.model : obj.model.exclude(obj.pk_hash)).filter(scope.merge(attr => value)).empty? or
          obj.errors.add attr, valid[:message]
        end
      end
    end
  end
end