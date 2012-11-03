module MongoidMapReduceHelper
  module Algorithm
  
    # groupby
    #   .map :name do |func|
    #     context :emit do |result|
    #       result.key => 'this.name', 
    #       result.values => {
    #         :count => 1,
    #         :total => 'this.price'
    #       }
    #     end
    #   end
    #   .reduce :name, :count => 'count +=1', :total => 'total += total' do |func|
    #     context :initial do |result|
    #       result.count => 0
    #       result.total => 0
    #       result << """
    #         var result = { count: 0, total: 0 }
    #       """
    #     end
    #     
    #     context :each_value do |result|
    #       result.count = '+= value.count',
    #       result.total = '+= value.total'
    #     end
    #     
    #     context :after_each do |result|
    #        result.average = 'result.total / result.count'
    #     end
    #     
    # groupby 
    #   .map(:name)
    #   .reduce(:name, :count => { :$count => :name }, :total => { $sum => :price })
    #   # or .reduce(:name, :count => :$count(name), :total => :$sum(price))
    # 
    # map = function(){
    #   var key = 'name';
    #   
    #   var columns = {
    #     name: {
    #       func: 'self',
    #       fields: ['name']
    #     },
    #     count: {
    #       func: 'count',
    #       fields: ['name']
    #     },
    #     total: {
    #       func:　'sum', 
    #       fields: ['price']
    #     }
    #   };
    #   
    #   this.pickAll = function(columns) {
    #     var result = {};
    #     
    #     for (var key in columns){
    #       var col = columns[key];
    #       var field = col.fields[0];
    #       
    #       switch(col.func){
    #         case "self": //ignore
    #           break;
    #         case "count":
    #           result[key] = 1;
    #           break;
    #         case "sum":
    #           result[key] = field;
    #           break;
    #       }
    #     }
    #     return result;
    #   }
    #   
    #   var value = pickAll(columns);
    #   
    #   emit(key, value );
    # }
    # 
    # reduce = function(key, values){
    #   this.count = function(result, fields){
    #     return result + 1;
    #   }
    #   
    #   this.sum = function(result, fields){
    #     var field = fields[0];
    #     return result + field;
    #   }
    #   
    #   this.max = function(result, fields) {
    #     var field = fields[0];
    #     return result < field ? field : result;
    #   }
    #   
    #   this.min = function(result, fields) {
    #     var field = fields[0];
    #     return result > field ? field : result;
    #   }
    #   
    #   this.
    #   
    #   var columns = {
    #     name: {
    #       func: 'self',
    #       fields: ['name']
    #     },
    #     count: {
    #       func: 'count',
    #       fields: ['name']
    #     },
    #     total: {
    #       func:　'sum', 
    #       fields: ['price']
    #     }
    #   }
    #   var result = initialAll(columns);
    #   
    #   values.forEach(function(value){
    #     for(var n in columns){
    #       col = columns[n];
    #       result[n] = this[col.func](result[n], col.fields);
    #     }
    #   })
    # }
    class GroupBy < Base

      attr_accessor :keys_params, :columns_params, :having_params

      def function_context
        @function_context ||= MongoidMapReduceHelper::Context::GroupBy.new(self)
      end

      # map :name do
      #   context :emit do |result|
      #     result.key = 'this.name'
      #     result.values = {
      #       :count => 1,
      #       :total => 'this.price'
      #     }
      #   end
      # end        
      def group_by(*args, &block)
        @keys_params = if args.size > 1 then
            concat_parameters_hash(*args)
        else
            args.first
        end
        
        function_context.eval(&block) if block_given?
        self
      end

      def columns(*args, &block)
        @columns_params = concat_parameters_hash *args
        function_context.eval(&block) if block_given?
        self
      end

      def having(arg, &block)
        @having_params = arg.to_a.first
        function_context.eval(&block) if block_given?
        self          
      end

      private
        def generate_map
          template = <<-JS
            ////////// generate map function
            function(){
              <%= yield :emit %>
            }
          JS

          cb = MongoidMapReduceHelper::Builder::GroupBy.new(function_context)
          js_func_compiler = ERB.new(template)
          js_func_compiler.result(cb.getbinding)            
        end

        def generate_reduce
          template = <<-JS
            ////////// generate reduce function
            function(key, values){
              <%= yield :initial %>

              values.forEach(function(value){
                <%= yield :each_value %>
              });

              <%= yield :after_each %>
              
              return result;
            }
          JS
          cb = MongoidMapReduceHelper::Builder::GroupBy.new(function_context)
          js_func_compiler = ERB.new(template)
          js_func_compiler.result(cb.getbinding)
        end

        def generate_finalize
          template = <<-JS
            ////////// generate finalize function
            function(key, value){
              <%= yield :finalize %>
            }
          JS
          cb = MongoidMapReduceHelper::Builder::GroupBy.new(function_context)
          js_func_compiler = ERB.new(template)
          js_func_compiler.result(cb.getbinding)            
        end
    end
  end
end