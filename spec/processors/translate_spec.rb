require 'spec_helper'

describe CsvPiper::Processors::Translate do
  let(:source) { { } }
  let(:transformed) { { "A" => 1, "B" => 2, "C" => 3 } }
  let(:transformed_input) { transformed.dup }
  let(:mapping) { {"A" => {1 => 11, 2 => 22} , "B" => {1 => 'a', 2 => 'b'}, "D" => {3 => 99} } }
  let(:errors_input) { CsvPiper::Errors::Row.new(1) }

  it 'does not mutuate erros' do
    _, errors = described_class.new(mapping: {}).process(source, {}, errors_input)
    expect(errors).to be(errors_input)
  end

  context 'with all translations matching' do
    subject { described_class.new(mapping: mapping).process(source, transformed_input, errors_input)[0] }
    it 'maps according to mapping' do
      mapped = subject
      expect(mapped["A"]).to eq(11)
      expect(mapped["B"]).to eq('b')
    end

    it 'does not touch keys with no mapping' do
      expect(subject["C"]).to eq(3)
    end

    it 'does not add an empty key for extra mappings' do
      expect(subject.has_key?("D")).to eq(false)
    end
  end

  context 'when no matching mapping value' do
    let(:transformed) { { "D" => 7 } }
    let(:mapping) { {"D" => {3 => 99} } }
    let(:add_errors) { false }
    let(:pass_through_on_no_match) { false }
    subject do
      described_class.new(mapping: mapping,
        add_error_on_missing_translation: add_errors, pass_through_on_no_match: pass_through_on_no_match)
      .process(source, transformed_input, errors_input)
    end

    context 'pass_through_on_no_match is off' do
      let(:pass_through_on_no_match) { false }
      it 'maps to nil' do
        expect(subject[0]["D"]).to be_nil
      end
    end

    context 'pass_through_on_no_match is on' do
      let(:pass_through_on_no_match) { true }
      it 'maps to original value' do
        expect(subject[0]["D"]).to eq(7)
      end
    end

    context 'add errors is off' do
      let(:add_errors) { false }
      it 'does not add an error' do
        expect(subject[1].errors).to be_empty
      end
    end

    context 'add errors is on' do
      let(:add_errors) { true }
      it 'adds an error' do
        expect(subject[1].errors["D"]).to eq(["No mapping for value 7"])
      end
    end
  end
end
