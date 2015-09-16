module CsvPiper
  module Processors
    class ErrorCollector
      attr_reader :errors
      def initialize
        @errors = {}
      end

      def process(source, transformed, errors)
        @errors[errors.row_index] = errors unless errors.empty?
        [transformed, errors]
      end
    end
  end
end
