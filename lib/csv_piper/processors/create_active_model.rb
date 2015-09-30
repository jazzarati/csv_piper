module CsvPiper
  module Processors
    class CreateActiveModel
      def initialize(model_class)
        @model_class = model_class
      end

      def process(_source, transformed, errors)
        model = @model_class.new(transformed)

        model.save if model.valid? && errors.empty?

        errors.errors.merge!(model.errors.to_hash) do |_key, old_val, new_val|
          old_val + new_val
        end

        transformed = transformed.merge({ "#{@model_class.name.underscore}_model".to_sym => model })
        [transformed, errors]
      end
    end
  end
end
