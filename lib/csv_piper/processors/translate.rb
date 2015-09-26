module CsvPiper
  module Processors
    class Translate
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
