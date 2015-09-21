module CsvPiper
  module Processors
    class CollectOutput
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
