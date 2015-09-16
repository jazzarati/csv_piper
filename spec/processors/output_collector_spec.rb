require 'spec_helper'

describe CsvPiper::Processors::OutputCollector do
  let(:row1) { { awesome: :magic } }
  let(:row2) { { tragic: :tragedy } }
  let(:row3) { { fantastic: :food } }
  let(:no_errors) { CsvPiper::Errors::Row.new(1) }
  let(:contains_errors) do
    error = CsvPiper::Errors::Row.new(2)
    error.add(:key,'error')
    error
  end


  before do
    collector.process({},row1,no_errors)
    collector.process({},row2,contains_errors)
    collector.process({},row3,no_errors)
  end

  describe 'when collecting all output (default)' do
    let(:collector) { described_class.new }
    it 'collects each rows output' do
      expect(collector.output).to eq( [row1, row2, row3] )
    end
  end

  describe 'when not collecting output with errors' do
    let(:collector) { described_class.new(collect_when_invalid: false) }
    it 'collects only valid row output' do
      expect(collector.output).to eq( [row1, row3] )
    end
  end
end
