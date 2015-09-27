module CsvPiper
  module Processors
    # Collects errors for use after processing.
    # Instantiate and keep a reference, then once processing complete retrieve errors through #errors
    class CollectErrors
      # @return[Hash] Holds all of the errors for each row that was processed
      # { row_index => { errors_key => array_of_errors } }
      attr_reader :errors
      def initialize
        @errors = {}
      end

      def process(_source, transformed, row_errors)
        @errors[row_errors.row_index] = row_errors.errors unless row_errors.empty?
        [transformed, errors]
      end
    end
  end
end
