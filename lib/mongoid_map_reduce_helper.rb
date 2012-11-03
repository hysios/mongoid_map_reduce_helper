$: << "lib"
require "mongoid_map_reduce_helper/version"
require "active_support/concern"
require "active_support/inflector"
require "mongoid_map_reduce_helper/helper"

module MongoidMapReduceHelper

  autoload :Helper, 'mongoid_map_reduce_helper/helper'

  module Algorithm
    autoload :Base,     "mongoid_map_reduce_helper/algorithm"
    autoload :GroupBy,  "mongoid_map_reduce_helper/algorithm/group_by"
  end

  module Builder
    autoload :Base,     "mongoid_map_reduce_helper/builder"
    autoload :GroupBy,  "mongoid_map_reduce_helper/builder/group_by"
  end

  module Expression
    autoload :Parameter,        "mongoid_map_reduce_helper/expression"
    autoload :AggregationParameterError, "mongoid_map_reduce_helper/expression"
  end

  module Context
    autoload :Base,     "mongoid_map_reduce_helper/context"
    autoload :GroupBy,  "mongoid_map_reduce_helper/context/group_by"
  end
end
