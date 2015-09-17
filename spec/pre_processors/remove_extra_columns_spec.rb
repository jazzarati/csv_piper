require 'spec_helper'

RSpec.describe "CsvPiper::PreProcessors - RemoveExtraColumns" do
  let(:source) do
    {
      "Deal Name" => '',
      ' ' => nil,
      '' => nil,
      nil => nil
    }
  end
  let(:errors_input) { {} }

  describe CsvPiper::PreProcessors::RemoveEmptyColumns do
    it 'removes empty column' do
      new_source, _ = described_class.new.process(source, errors_input)
      expect(new_source).to eq( "Deal Name" => '' )
    end

    it 'does not mutuate erros' do
      _, errors = described_class.new.process(source, errors_input)
      expect(errors).to be(errors_input)
    end
  end

  describe CsvPiper::PreProcessors::RemoveNilColumns do
    it 'removes nil columns' do
      new_source, _ = described_class.new.process(source, errors_input)
      expect(new_source).to eq( "Deal Name" => '', ' ' => nil, '' => nil )
    end

    it 'does not mutuate erros' do
      _, errors = described_class.new.process(source, errors_input)
      expect(errors).to be(errors_input)
    end
  end

  # # For testing performance of different methods
  # it 'benchmarks' do
  #   require 'benchmark'

  #   small_source = Hash[ (0...10).map {|v| [v.to_s,v.to_s]} ]
  #   large_source = Hash[ (0...1000).map {|v| [v.to_s,v.to_s]} ]
  #   orig = CsvPiper::PreProcessors::RemoveEmptyColumns.new
  #   alt = CsvPiper::PreProcessors::RemoveNilColumns.new

  #   n = 1000000
  #   p "10 col * 1M row"
  #   Benchmark.bm(7) do |x|
  #     x.report("empty") { n.times do ; orig.process(small_source, nil) ; end }
  #     x.report("nil") { n.times do ; alt.process(small_source, nil) ; end }
  #   end

  #   n = 10000
  #   puts "\n"
  #   p "1000 col * 10K row"
  #   Benchmark.bm(7) do |x|
  #     x.report("empty") { n.times do ; orig.process(large_source, nil) ; end }
  #     x.report("nil") { n.times do ; alt.process(large_source, nil) ; end }
  #   end
  # end
end
