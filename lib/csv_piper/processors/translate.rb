module CsvPiper
  module Processors
    # Used to convert the values in the transformed hash according a provided mapping hash. { key => { 'value' => 'new_value', 'value2' => 'new_value2' } }
    class Translate

      # @param mapping: [Hash] Mapping to use for translation: { key => { 'value' => 'new_value', 'value2' => 'new_value2' } }
      # @param add_error_on_missing_translation: [Boolean] By default errors are not added when there is no matching
      #    value found in the mapping. When set to +true+ errors will be added to the key if no matching value found.
      # @param pass_through_on_no_match: By default when there is no matching value the value will become +nil+.
      #    When set to +true+, the value will remain unchanged if there is no matching value to translate using.
      def initialize(mapping: , add_error_on_missing_translation: false, pass_through_on_no_match: false)
        @add_error = add_error_on_missing_translation
        @pass_through =  pass_through_on_no_match
        @mapping = mapping
      end

      def process(_source, transformed, errors)
        mappings_to_apply = @mapping.select { |key,_| transformed.has_key?(key) }

        transformed = mappings_to_apply.each_with_object(transformed) do |(key, translation), memo|
          new_value = translation[memo[key]]
          errors.add(key, "No mapping for value #{memo[key]}") if @add_error && new_value.nil?
          new_value = new_value || memo[key] if @pass_through
          memo[key] = new_value
        end

        [transformed, errors]
      end
    end
  end
end
