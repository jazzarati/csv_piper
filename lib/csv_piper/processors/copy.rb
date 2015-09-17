module CsvPiper
  module Processors
    class Copy
      def initialize(mapping = nil)
        mapping = Hash[ mapping.map { |val| [val, val] } ] if mapping.is_a?(Array)
        @mapping = mapping
      end

      def process(source, transformed, errors)
        if @mapping.is_a?(Hash)
          transformed = @mapping.each_with_object(transformed) do |(key, new_key), memo|
            memo[new_key] = source[key]
          end
        else
          transformed = transformed.merge(source)
        end
        [transformed, errors]
      end
    end
  end
end
