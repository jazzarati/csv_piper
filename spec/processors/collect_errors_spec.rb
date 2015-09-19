require 'spec_helper'

describe CsvPiper::Processors::CollectErrors do
  let(:row) { 7 }
  let(:collector) { described_class.new }

  def error_for_row(row_index)
    errors = CsvPiper::Errors::Row.new(row_index)
    errors.add(:key, 'value')
    errors
  end

  context 'with errors' do
    let(:row_error) { error_for_row(2) }
    before do
      collector.process({},{},row_error)
      collector.process({},{},CsvPiper::Errors::Row.new(3))
    end

    it 'collects against a row index' do
      expect(collector.errors[2]).to be(row_error.errors)
    end

    it 'does not collect where there are no errors' do
      expect(collector.errors[3]).to be_nil
    end
  end
end
