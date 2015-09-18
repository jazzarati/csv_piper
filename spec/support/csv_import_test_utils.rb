module CsvImportTestUtils
  module PreProcessors
    class UpCase
      def process(source, errors)
        transformed = source.each_with_object({}) { |(key, value), memo| memo[key] = value.upcase }
        [transformed, errors]
      end
    end

    class Error
      def initialize(error_msg)
        @error_msg = error_msg
      end

      def process(source, errors)
        errors.add(:phony_error, @error_msg)
        [source, errors]
      end
    end
  end

  module Processors
    class Error
      def initialize(error_msg)
        @error_msg = error_msg
      end

      def process(source, transformed, errors)
        errors.add(:phony_error, @error_msg)
        [transformed, errors]
      end
    end

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

end
