module MongoidMapReduceHelper
  module Expression

    class AggregationParameterError < StandardError; end

    FUNCTION_VALID        = /^\$/
    AGGREGATION_STRING    = /(?<function>\w+)\((?<params>\w+)\)/i
    COUNT_FUNCTION        = /count\((\w+)\)/i
    SUM_FUNCTION          = /sum\((\w+)\)/i
    MAX_FUNCTION          = /max\((\w+\))/i
    MIN_FUNCTION          = /min\((\w+)\)/i
    AGGREGATION_FUNCTIONS = %w(count min max sum average)

    class Parameter
      #   .columns(:name, :count => :'$count(name)', :total => :'$sum(price)')
      # 
      #   .columns(:name, :count => 'count +=1', :total => 'total += total')
      #   
      #   .columns(:name, :count => { :$count: 'name' }, :total => {:$sum: 'price' })
      # Symbol 表达式解析器
      def parse(args)
        result = {}
        args.each do |key, value|
          parse_value(value, {:target => result, :key => key})
        end
        result
      end

      # .group_by(:name)
      #   => emit( this.name, {... });
      #   
      # .group_by("name")
      #   => emit( name, {... });
      # 
      # .group_by(/hello/)
      #   => emit( /hello/, {... });
      # 
      # .group_by(:name, :create_date)
      #   => emit( {name: this.name, create_date: this.create_date} , {... });
      def parse_key(keys)
        case keys
        when String
          keys
        when Symbol
          this(keys)
        when RegExp
          "//#{keys.to_s}//"
        when Hash
          # { name1: nil, name2: nil }
          result = {}
          keys.map do |k,v|
            result[k] = this(k) unless v.nil?
          end
          result.to_json
        else 
          throw AggregationParameterError
            .new "invalid key parameter type, permit String, Symbol, RegExp, a Symbol of array"
        end
      end

      # having(:'$sum(price)' => '> 1000')
      # =>
      #   $sum(price): {
      #     func: 'sum',
      #     having: true,
      #     fields: ['price'],
      #     code_string: '> 1000'
      #   }
      # 
      def parse_key_value(key, value)
        result = {}
        name = nameable key
        if key.is_a?(Symbol) && key.to_s =~ FUNCTION_VALID # 如果值是 Symbol 且满足 Function 格式
          aggregation_string = key.to_s[1..-1] # 去除首字符 '$'

          if m = AGGREGATION_STRING.match(key)
            func, params = m[:function], [m[:params]]
            
            throw AggregationParameterError
              .new "invalid aggregation function: #{func}" unless AGGREGATION_FUNCTIONS.include? func
            
            result[name] = {func: func, having: true, fields: params, code_string: value}
          else
            throw AggregationParameterError
              .new "invalid aggregation expression format: #{value}"
          end        
        else
          throw AggregationParameterError
            .new "invalid symbol #{value}"
        end
        result
      end

      def nameable(key)
        key.to_s.gsub(/[\(|\)]+/, '_')
      end

      def this(name)
        "this." + name.to_s
      end

      def code_string(code_string)
        CodeString.new(code_string)
      end

      def parse_value(value, options)
        # name: {
        #   func: 'self'
        # },
        # total: {
        #   func: 'sum'
        #   fields: 'price'
        # }
        target, key = valid_options options

        case value
        when NilClass then target[key] = {func: 'self'}
        when Symbol
          if value.to_s =~ FUNCTION_VALID # 如果值是 Symbol 且满足 Function 格式
            aggregation_string = value.to_s[1..-1] # 去除首字符 '$'
            parser_aggregation aggregation_string, options
          else
            throw AggregationParameterError
              .new "invalid symbol #{value}"
          end
        when String
           target[key] = {func: 'code_string', expression: value}
        else
          # when Hash
          # todo: is Hash expression
          # value.each do |key, val|
          #   if key.is_a? Symbol && key.to_s && key ~= FUNCTION_VALID
          #     val = val.to_s

          # end
        end
      end

      def parser_aggregation(value, options)
        target, key = valid_options options

        if m = AGGREGATION_STRING.match(value)
          func, params = m[:function], [m[:params]]

          throw AggregationParameterError
            .new "invalid aggregation function: #{func}" unless AGGREGATION_FUNCTIONS.include? func
          target[key] = {func: func, fields: params}
        else
          throw AggregationParameterError
            .new "invalid aggregation expression format: #{value}"
        end        
      end

      def valid_options(options)
        if options[:target].nil? && options[:key].nil?
          throw ArgumentError.new "miss :target or :key in options params"
        end 
        [options[:target], options[:key]]
      end
    end

    class DomainValue
      def initialize(name, domain = nil, options = { exp: true})
        @domain, @name, @options = domain, name, options
      end

      def to_s
        if @options[:exp]
          to_exp
        else
          super
        end
      end

      def to_exp
        if @domain.nil?
          @name
        else
          @domain.to_s + '.' + @name.to_s
        end
      end
    end

    class ExpressionBase
      def initialize(store, left, right)
        @store, @left, @right = store, left, right
      end
    end

    class SelfExpression < ExpressionBase
      def to_exp
        "#{@store} = #{@right}"
      end
    end

    class CountExpression < ExpressionBase
      def to_exp
        # "#{@store} = #{@left} + (#{@right} == undefined || #{@right} == null ? 0 : 1)"
        "#{@store} += #{@right}"
      end
    end

    class SumExpression < ExpressionBase
      def to_exp
        "#{@store} = #{@left} + #{@right}"
      end
    end

    class MinExpression < ExpressionBase
      def to_exp
        "#{@store} = #{@left} < #{@right} ? #{@left} : #{@right}"
      end

    end

    class MaxExpression < ExpressionBase
      def to_exp
        "#{@store} = #{@left} > #{@right} ? #{@left} : #{@right}"
      end

    end

    class AverageExpression < ExpressionBase
      def to_exp
        """
        #{@store}.count = #{@left}.count + #{@right}.count;
        #{@store}.sum = #{@left}.sum + #{@right}.sum"""
      end
    end

    class HavingExpression < ExpressionBase
      def to_exp
        <<-JAVASCRIPT

          if (!(#{@store} #{@right})) {
            value.__having_filtered = true;
          } 
          delete #{@store};
        JAVASCRIPT
      end
    end

    class CodeString

      def initialize(code_string)
        @code = code_string
      end

      def as_json(options=nil)
        @code
      end

      def to_s
        @code
      end

    end
  end
end
