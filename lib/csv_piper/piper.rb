module CsvPiper
  class Piper
    HEADER_LINE_INDEX = 1
    FIRST_DATA_LINE_INDEX = 2
    CSV_HEADER_OPTIONS = { headers: true, return_headers: true, skip_blanks: true, skip_lines: /^(\s*,)*$/ }

    def initialize(io_stream:, pre_processors: [], processors: [], csv_options: {}, required_headers: [])
      @pre_processors = pre_processors
      @processors = processors
      @required_headers = required_headers
      @csv_options = csv_options.merge(CSV_HEADER_OPTIONS)
      @csv_options = @csv_options.merge(skip_lines: "^(\s*#{@csv_options[:col_sep]})*$") if @csv_options[:col_sep]
      @io = io_stream
    end

    def has_required_headers?
      missing_headers.empty?
    end

    def missing_headers
      headers = csv.headers
      required_headers.reject { |header| headers.include?(header) }
    end

    def process
      validate_process_configuration!
      validate_headers!

      process_csv_body

      self
    end

    private

    attr_reader :io, :pre_processors, :processors, :required_headers, :csv_options

    def process_csv_body
      csv.each.with_index(FIRST_DATA_LINE_INDEX) do |row, index|
        processed_data, row_errors = process_row(index, row.to_hash)
      end
    end

    def process_row(row_index, row)
      pre_processed_row, row_errors = pre_processors.reduce([row, Errors::Row.new(row_index)]) do |memo, processor|
        output = processor.process(*memo)
        return if output.nil?
        output
      end

      frozen_row = pre_processed_row.freeze

      processed_data = {}
      processed_data, row_errors = processors.reduce([processed_data, row_errors]) do |memo, processor|
        output = processor.process(frozen_row, *memo)
        return if output.nil?
        output
      end
    end

    def csv
      @csv ||= begin
        csv_object = CSV.new(io, csv_options)
        csv_object.readline # Read headers through
        csv_object
      end
    end

    def validate_process_configuration!
      raise 'Requires an IO object to process from' if io.nil?
    end

    def validate_headers!
      raise "Missing required headers: #{missing_headers.join(', ')}" unless has_required_headers?
    end
  end
end
