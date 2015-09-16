module CsvPiper
  class Builder
    def initialize
      @pre_processors = []
      @processors = []
    end

    def from(io_stream)
      @io = io_stream
      self
    end

    def with_pre_processors(pre_processors)
      @pre_processors += pre_processors
      self
    end

    def with_processors(processors)
      @processors += processors
      self
    end

    def with_csv_options(options)
      @csv_options = options
      self
    end

    def requires_headers(headers)
      @required_headers = headers
      self
    end

    def build
      build_options = { io_stream: @io, pre_processors: @pre_processors, processors: @processors }
      build_options[:csv_options] = @csv_options if @csv_options
      build_options[:required_headers] = @required_headers if @required_headers
      Piper.new(build_options)
    end
  end
end
