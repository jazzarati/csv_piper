module CsvImportTestUtils
  class CSVMockFile
    extend Forwardable

    def self.create(headers, separator = ',')
      csv = new(headers, separator)
      yield csv if block_given?
      csv.rewind
      csv
    end

    attr_reader :headers, :io, :seperator
    delegate [:readline, :readlines, :rewind, :gets] => :io

    # Using a StringIO object instead of reading/writing files from disk
    def initialize(headers, seperator = ',')
      raise "Must have atleast one header" if headers.empty?
      @headers = headers.sort
      @seperator = seperator
      @io = StringIO.new("w+")
      io.puts(@headers.join(seperator))
    end

    def add(row_hash)
      raise "Headers don't match #{row_hash.keys - headers}" unless (row_hash.keys - headers).empty?
      row = headers.map { |key| row_hash[key] || '' }.join(seperator)
      io.puts(row)
    end

    def write_to_file(path)
      File.open(path, 'w+') do |f|
        f.write(io.read)
      end
    end
  end

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
