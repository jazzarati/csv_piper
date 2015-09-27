module CsvPiper
  module Processors
    # Use to copy data from source row to transformed hash. Does not add any errors.
    class Copy
      # @param mapping: [nil, Array, Hash{source_key => new_key}] (Defaults to +nil+)
      #     - When +nil+: All contents of the source hash will be copied across to the transformed hash
      #     - When an +Array+: Only the matching keys will be copied to the transformed hash
      #     - When a +Hash+: Only the matching keys will be copied to the transformed hash but they will be copied onto the transformed hash with a new key value (mapping = +{ source_key => new_key }+ )
      #
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
