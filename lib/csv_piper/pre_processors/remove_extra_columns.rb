module CsvPiper
  module PreProcessors
    class RemoveEmptyColumns
      def process(origin, errors)
        modified_origin = origin.reject { |key, _| key.nil? || key.strip.empty? }
        [modified_origin, errors]
      end
    end

    # Just removing nil is significanlty faster for large csvs (100M+ cells)
    # (10M cells = ~20x faster on 10 col row [3.8s vs 0.19s], ~100x faster on 1000 col row [3.8s vs 0.035s]).
    # Even better is your processors don't need this pre-processing.
    class RemoveNilColumns
      def process(origin, errors)
        origin.delete(nil)
        [origin, errors]
      end
    end
  end
end
