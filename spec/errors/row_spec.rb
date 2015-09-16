require 'spec_helper'

describe CsvPiper::Errors::Row do
  let(:row) { 7 }
  let(:errors) { described_class.new(row) }

  it 'references a row' do
    expect(errors.row_index).to eq(row)
  end

  it 'delegates empty? to its errors' do
    expect(errors).to be_empty
    errors.add(:a, 'error')
    expect(errors).not_to be_empty
  end

  context 'with errors' do
    before do
      errors.add(:field1, 'Error 1')
      errors.add(:field1, 'Error 2')
      errors.add(:field2, 'Error 3')
    end

    it 'collects against a key' do
      expect(errors.errors).to eq(field1: ['Error 1', 'Error 2'], field2: ['Error 3'])
    end
  end
end
