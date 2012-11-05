require 'mongoid'
require 'mongoid/criteria'

module MongoidMapReduceHelper
  module Helper
    extend ActiveSupport::Concern

    module ClassMethods
      def algorithm(algorithm_sym)
        # algorithm_handle = if algorithms[algorithm_sym].nil? 
        #   algorithm_name = algorithm_sym.to_s
        #   algorithm_klass = "MongoidMapReduceHelper::Algorithm::#{algorithm_name.classify}"
        #   algorithm_handle =  algorithm_klass.constantize.new(self)
        #   algorithms[algorithm_sym] = algorithm_handle
        # else
        #   algorithms[algorithm_sym]
        # end
        algorithm_name = algorithm_sym.to_s
        algorithm_klass = "MongoidMapReduceHelper::Algorithm::#{algorithm_name.classify}"
        algorithm_handle =  algorithm_klass.constantize.new(self)
      end

      def with_algorithm
        Threaded.sessions[:algorithm] = {}
      end

      def algorithms
        @algorithms ||= {}
      end
    end
  end
end

module Mongoid
  Criteria.send(:include, MongoidMapReduceHelper::Helper::ClassMethods)
end