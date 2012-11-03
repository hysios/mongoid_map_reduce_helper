module MongoidMapReduceHelper
  module Context


    class GroupBy < Base

      def call_context(name, *args, &block)
        context = contexts[name]
        context.call(block.call(*args))
      end

      # context :emit do |result|
      #   result.key => 'this.name', 
      #   result.values => {
      #     :count => 1,
      #     :total => 'this.price'
      #   }
      # end
      for_context :emit do |revert|

        values = revert.values.map do |key,value|
          "result.#{key} = #{value.inspect}"
        end

        "emit(#{revert.key}, { #{ values.join(',') } });"
      end

      # context :initial do |result|
      #   result.count => 0
      #   result.total => 0
      #   --- or ----
      #   result << """
      #     var result = { count: 0, total: 0 }
      #   """
      # end
      for_context :initial do |revert|
        results = revert.map do |key, value|
          "result.#{key} = #{value.inspect}"
        end

        "var result = { #{results.join(",")} };"
      end

      # context :each_value do |result|
      #   result.count = '+= value.count',
      #   result.total = '+= value.total'
      # end
      for_context :each_value do |revert|
        results = revert.map do |key, value|
          "result.#{key} = #{value};"
        end
        results
      end

      # context :after_each do |result|
      #    result.average = 'result.total / result.count'
      # end
      for_context :after_each do |revert|
        "result.average = #{revert.average}"
      end
 
    end
  end
end