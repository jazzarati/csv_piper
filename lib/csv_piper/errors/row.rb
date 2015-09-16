module CsvPiper
  module Errors
    class Row
      extend Forwardable
      delegate :empty? => :errors

      attr_reader :row_index, :errors

      def initialize(row_index)
        @row_index = row_index
        @errors = Hash.new { [].freeze }
      end

      def add(key, error)
        @errors[key] += [error]
      end
    end
  end
end
