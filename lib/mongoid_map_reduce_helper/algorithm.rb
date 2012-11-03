module MongoidMapReduceHelper
  module Algorithm
    # Sample 1
    # ========
    # Product
    #   .algorithm(:group_by)
    #   .group_by(:name)
    #   .columns(:name, :count => :'$count(name)', :total => :'$sum(price)')
    # 
    # Sample 2
    # ========
    # Product
    #   .algorithm(:group_by)
    #   .group_by(:name)
    #   .columns(:name, :count => 'count +=1', :total => 'total += total')
    #   
    # Sample 3
    # ========
    # Product
    #   .algorithm(:group_by)
    #   .group_by(:name)
    #   .columns do
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
    #   end    
    #  
    class Base
      include Enumerable

      attr_accessor :function_context

      delegate :[], :each, to: :map_reduce

      def initialize(host)
        @host = host
      end

      def out(options)
        @out_options = options
        self
      end

      private

        def out_options
          @out_options ||= {inline: 1}
        end

        def concat_parameters_hash(*args)
          hash = {}
          args.map do |arg|
            case arg 
              when Symbol, String then hash.store(arg.to_sym, nil)
              when Hash then hash.merge! arg
              else throw ArgumentError.new('Must Symbol, Hash or String')
            end
          end
          hash
        end

        def generate_map; end # pure method
        def generate_reduce; end # pure method
        def generate_finalize; end #pure method

        def map_reduce
          puts generate_map, generate_reduce, generate_finalize
          # MapReduce.new(collection, criteria, map, reduce)
          @host.map_reduce(generate_map, generate_reduce).out(out_options).finalize(generate_finalize)
        end
    end
  end
end