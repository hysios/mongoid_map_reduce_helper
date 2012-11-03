module MongoidMapReduceHelper
  module Context
    class Base

      attr_accessor :algorithor

      class << self
        def inherited(subclass)
          class_eval <<-RUBY, __FILE__, __LINE__+1
            redefine_method :class_contexts do
              @@#{subclass.name}_contexts = {}
            end
          RUBY
        end

        def for_context(name, &process)
          class_contexts[name] = process
        end

        def class_contexts
          @@class_contexts = {}
        end
      end

      def contexts
        self.class.class_contexts
      end

      def is_available?(name)
        contexts.keys.include?(name)
      end

      def initialize(handle)
        @algorithor = handle
      end
    end
  end
end