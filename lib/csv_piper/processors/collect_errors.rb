module CsvPiper
  module Processors
    class CollectErrors
      attr_reader :errors
      def initialize
        @errors = {}
      end

      def process(source, transformed, row_errors)
        @errors[row_errors.row_index] = row_errors.errors unless row_errors.empty?
        [transformed, errors]
      end
    end
  end
end
