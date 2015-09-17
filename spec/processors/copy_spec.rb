require 'spec_helper'

describe CsvPiper::Processors::Copy do
  let(:source) { { "A" => 1, "B" => 2, "C" => 3 } }
  let(:errors_input) { {} }

  it 'does not mutuate erros' do
    _, errors = described_class.new.process(source, {}, errors_input)
    expect(errors).to be(errors_input)
  end

  context 'default copy option' do
    let(:expected_copy) { source }
    it 'copies all keys' do
      transformed, _ = described_class.new.process(source, {}, errors_input)
      expect(transformed).to eq(expected_copy)
    end
  end

  context 'array of keys copy option' do
    let(:mapping) { ["A", "D"] }
    let(:expected_copy) { { "A" => 1,  "D" => nil } }
    it 'adds entries even if source does not have an entry' do
      transformed, _ = described_class.new(mapping).process(source, {}, errors_input)
      expect(transformed).to eq(expected_copy)
    end
  end

  context 'hash of keys to map during copy option' do
    let(:mapping) { { "A" => "Z", "D" => "Y" } }
    let(:expected_copy) { { "Z" => 1,  "Y" => nil } }
    it 'maps entries and adds keys even if source does not have an entry' do
      transformed, _ = described_class.new(mapping).process(source, {}, errors_input)
      expect(transformed).to eq(expected_copy)
    end
  end
end
