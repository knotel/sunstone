module Sunstone
  module Type
    class DateTime < Value
      
      private
      
      def _type_cast_for_json(value)
        value.iso8601(3) if value
      end
      
      def _cast_value(string)
        return string unless string.is_a?(::String)
        return if string.empty?
        
        ::DateTime.iso8601(string) || ::DateTime.parse(string)
      end
      
    end
  end
end