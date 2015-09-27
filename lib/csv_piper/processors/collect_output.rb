module CsvPiper
  module Processors
    # Collects transformed objects for use after processing.
    # Instantiate and keep a reference, then once processing complete retrieve transformed objects through #output
    class CollectOutput
      # @return[Array] Holds all of the transformed objects for each row that was processed
      # { row_index => { errors_key => array_of_error } }
      attr_reader :output
      def initialize(collect_when_invalid: true)
        @output = []
        @collect_when_invalid = collect_when_invalid
      end

      def process(_source, transformed, errors)
        @output << transformed if @collect_when_invalid || errors.empty?
        [transformed, errors]
      end
    end
  end
end
