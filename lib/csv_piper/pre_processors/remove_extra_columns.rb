module CsvPiper
  module PreProcessors
    class RemoveExtraColumns
      def process(origin, errors)
        modified_origin = origin.reject { |key, value| key.nil? || key.empty? }
        [modified_origin, errors]
      end
    end
  end
end
