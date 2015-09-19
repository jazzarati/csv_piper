module CsvImportTestUtils
  module PreProcessors
    class UpCase
      def process(source, errors)
        transformed = source.each_with_object({}) { |(key, value), memo| memo[key] = value.upcase }
        [transformed, errors]
      end
    end
  end

  module Processors
    class PassThrough
      def process(source, transformed, errors)
        [transformed.merge(source), errors]
      end
    end

    class DownCase
      def process(source, transformed, errors)
        new_transformed = transformed.each_with_object({}) { |(key, value), memo| memo[key] = value.downcase }
        [new_transformed, errors]
      end
    end
  end

  module FlexiProcessors # Handle both processors and pre-processors
    class SkipRows
      def initialize(rows)
        @rows = rows
      end

      def process(*args)
        return nil if @rows.include? args[-1].row_index
        args[-2..2]
      end
    end

    class Error
      def initialize(error_msg)
        @error_msg = error_msg
      end

      def process(*args)
        args[-1].add(:phony_error, @error_msg)
        args[-2..2]
      end
    end
  end
end
