require 'spec_helper'

RSpec.describe CsvPiper::PreProcessors::RemoveExtraColumns do
  let(:source) do
    {
      "Deal Name" => '',
      '' => ''
    }
  end
  let(:errors_input) { {} }

  it 'removes empty column' do
    new_source, _ = described_class.new.process(source, errors_input)
    expect(new_source).to eq( "Deal Name" => '' )
  end

  it 'does not mutuate erros' do
    _, errors = described_class.new.process(source, errors_input)
    expect(errors).to be(errors_input)
  end
end
