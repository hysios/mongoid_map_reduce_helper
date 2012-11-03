module MongoidMapReduceHelper
  module Builder
    class Base
      attr_accessor :function_context

      IGNORE_FUNCTIONS = %w()
      HOOK_AFTERFIX = /(_with|_without)_hook_block/

      @@before_call = [nil, {}]
      
      def expression
        @expression ||= MongoidMapReduceHelper::Expression::Parameter.new
      end

      def initialize(context)
        @function_context = context
        func_name, options = @@before_call
        klass = self.class

        unhook_methods.each do |method|
          method = method.to_sym
          klass.class_eval do
            hook_name = "#{method}_with_hook_block".to_sym
            unhook_name = "#{method}_without_hook_block".to_sym
            define_method hook_name do
              if func_name.is_a? Symbol
                unless send(func_name, method) == false
                  send(unhook_name)
                end
              end
            end
            
            alias_method_chain method, :hook_block
          end

        end
      end

      def unhook_methods
        func_name, options = @@before_call
        klass = self.class
        methods = klass.instance_methods(false) - IGNORE_FUNCTIONS - [ func_name ]
        hooked_methods = methods.grep(HOOK_AFTERFIX)
        methods -= hooked_methods
        methods -= hooked_methods.map {|m| m.to_s.gsub(HOOK_AFTERFIX, '').to_sym }
        methods = options_patch(methods, options)
      end


      def getbinding
        block_binding do |part|
          self.send(part) if self.respond_to? part
        end
      end

      def block_binding(&block)
        binding 
      end

      def algorithor
        function_context.algorithor
      end

      def self.before_call(func_name, options = {})
        @@before_call = [func_name, options]
      end

      private
        def options_patch(methods, options)
          except = array_of(options[:except])
          only   = array_of(options[:only])
          
          if except
            methods - except
          elsif 
            methods.clone.delete_if { |a| only.include? a }
          end
        end

        def array_of(arg)
          arg = [arg] unless arg && arg.is_a?(Array) && arg.size > 1
        end
    end
  end
end