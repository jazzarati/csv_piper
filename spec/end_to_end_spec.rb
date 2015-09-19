require 'spec_helper'

describe 'end to end' do
  let(:required_headers) { ['Input 1','Process','Input 2','Result'] }
  let(:expected_output) do
    [
      { row: 2, equation: '1 + 1 == 2', valid: true },
      { row: 4, equation: '2 * 2 == 4', valid: true },
    ]
  end

  it 'processes a csv file' do
    output_collector = CollectProcessedEquations.new
    error_collector = CsvPiper::Processors::CollectErrors.new

    File.open(File.join(File.dirname(__FILE__),"/data/csv_1.csv")) do |file|

      csv_piper = CsvPiper::Builder.new.from(file)
        .requires_headers(required_headers)
        .with_processors([
          BuildEquation.new, EvaluateEquation.new, output_collector, error_collector
        ])
        .build

      csv_piper.process if csv_piper.has_required_headers?
    end

    output = output_collector.output
    errors = error_collector.errors

    expect(output).to eq(expected_output)
    expect(errors.size).to eq(1)
    expect(errors.keys.first).to eq(3)
    expect(errors[3].errors[:equation]).to eq(['anything * anything == 42 is not valid'])
  end

  class BuildEquation
    def process(source, transformed, errors)
      transformed[:equation] = [ source['Input 1'], source['Process'], source['Input 2'], '==', source['Result'] ].join(' ')
      [transformed, errors]
    end
  end

  class EvaluateEquation
    def process(source, transformed, errors)
      begin
        transformed[:valid] = eval(transformed[:equation]) == true
      rescue Exception
        errors.add(:equation, transformed[:equation] + ' is not valid')
      end
      [transformed, errors]
    end
  end

  class CollectProcessedEquations
    attr_reader :output
    def initialize
      @output = []
    end

    def process(source, transformed, errors)
      @output << {row: errors.row_index}.merge(transformed) if errors.empty?
      [transformed, errors]
    end
  end
end
