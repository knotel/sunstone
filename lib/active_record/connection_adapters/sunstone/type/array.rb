module ActiveRecord
  module ConnectionAdapters
    module Sunstone
      module Type
        class Array < ActiveRecord::Type::Value
          include ActiveRecord::Type::Mutable
          
          attr_reader :subtype
          delegate :type, to: :subtype
          
          def initialize(subtype)
            @subtype = subtype
          end
          
          def type_cast_for_database(value)
            super(value).to_json if value
          end
          
          def cast_value(string)
            return string unless string.is_a?(::String)
            return if string.empty?

            JSON.parse(string)
          end
         
        end
      end
    end
  end
end