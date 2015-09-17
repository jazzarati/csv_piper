module CsvPiper
  module Processors
    class CreateActiveModel
      def initialize(model_class)
        @model_class = model_class
      end

      def process(source, transformed, errors)
        model = @model_class.new(transformed)

        model.save if model.valid? && errors.empty?

        errors.errors.merge!(model.errors.to_hash) do |key, old_val, new_val|
          old_val + new_val
        end

        [transformed, errors]
      end
    end
  end
end
