module MongoidMapReduceHelper
  module Builder
    class GroupBy < Base

      before_call :before_call_context, :except => :columns

      def available_functions
        MongoidMapReduceHelper::Expression::AGGREGATION_FUNCTIONS
      end

      def before_call_context(name)
        if function_context.is_available?(name)
          function_context.call(name)
          false
        end
      end


      def emit
        result = ResultHash.new
        key = expression.parse_key algorithor.keys_params

        columns.map do |key, value|
          case value[:func]
          when "self" then result[key] = this_code(key.to_s)
          when "count" then result[key] = 1
          when  "min", "max", "sum"
            result[key] = this_code(value[:fields][0])
          when "average"
            average_result = ResultHash.new
            average_result[:count] = 1
            average_result[:sum] = this_code(value[:fields][0])
            result[key] = average_result
          end
        end
        template = <<-JAVASCRIPT
          emit(#{key}, #{result.to_javascript});
        JAVASCRIPT
      end

      def initial
        result = ResultHash.new
        columns.delete_if {|key,value| value[:func] == 'self' }
        columns.map do |key,value| 
          if available_functions.include?(value[:func])
            if value[:func] =~ /min|max/
              result[key] = expression.code_string("values[0]['#{key}']")
            elsif value[:func] =~ /average/
              result[key] = {count: 0, sum: 0}
            else
              result[key] = 0
            end
          end
        end

        <<-JAVASCRIPT
        var result = #{result.to_javascript};
        JAVASCRIPT
      end

      def each_value
        columns.map do |key, value|
          to_exp(key, value) + ";"
        end.join("\n")
      end

      def finalize
        # columns.find(:func => 'count')
        output = ""
        columns.each do |key, value| 
          if value[:func] =~ /average/
            output << """
              if (value.#{key}.count > 0)
                value.#{key} = value.#{key}.sum / value.#{key}.count;
            """
          end

          if value[:having]
            store = domain_value(key, :value)
            code = value[:code_string]
            output << to_func_exp("having", store, store, code) + ";\n"
          #   ['having', value[:code_string]]
          # else            
          end
        end
        output << "return value;"
      end

      private 
        def columns
          columns = expression.parse algorithor.columns_params
          having_columns = if !algorithor.having_params.nil?
            expression.parse_key_value *algorithor.having_params
          else
            {}
          end
          columns.merge(having_columns)
        end

        def domain_value(value, domain)
          MongoidMapReduceHelper::Expression::DomainValue.new(value, domain)
        end

        def this_code(value)
          expression.code_string("this." + value)
        end

        def to_exp(store, value)
          func = value[:func]
          field = domain_value(store, :value)
          store = domain_value(store, :result)
          to_func_exp(func, store, store, field)
        end

        def to_func_exp(func, store, left, right)
          exp_klass = "MongoidMapReduceHelper::Expression::#{func.capitalize}Expression".constantize
          exp = exp_klass.new(store, left, right)
          exp.to_exp
        end
    end

    class ResultHash < Hash

      def to_javascript
        hash = "{"
        kv = self.map do |key, value|
          if value.is_a? MongoidMapReduceHelper::Expression::CodeString
            "\"#{key}\": #{value}"
          else
            "\"#{key}\": #{value.to_json}"
          end
        end
        hash << kv.join(',') << "}"
      end

      alias :to_json :to_javascript

    end
  end
end