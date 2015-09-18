module CsvPiper
  module TestSupport
    class CsvMockFile
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
  end
end
