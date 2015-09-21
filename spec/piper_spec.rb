require 'spec_helper'

describe CsvPiper::Piper do
  it 'has a version number' do
    expect(CsvPiper::VERSION).not_to be nil
  end

  let(:basic_csv_row) { { "Attr 1" => 'Value 1', "Attr 2" => 'Value 2' } }
  let(:basic_headers) { basic_csv_row.keys }
  let(:output_collector) { CsvPiper::Processors::CollectOutput.new }
  let(:error_collector) { CsvPiper::Processors::CollectErrors.new }

  describe 'file setup is valid' do
    describe 'collectors' do
      let(:basic_csv_row2) { { "Attr 1" => 'Value 2', "Attr 2" => 'Value 3' } }
      let(:file) do
        CsvPiper::TestSupport::CsvMockFile.create(basic_headers) do |f|
          f.add(basic_csv_row) ; f.add(basic_csv_row2)
        end
      end

      describe 'output collector' do
        it 'collect output' do
          CsvPiper::Builder.new.from(file)
            .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector])
            .build.process

          expect(output_collector.output).to eq([basic_csv_row, basic_csv_row2])
        end
      end

      describe 'error collector' do
        it 'collect errors' do
          CsvPiper::Builder.new.from(file)
            .with_processors([CsvImportTestUtils::FlexiProcessors::Error.new("Phony Error"), error_collector])
            .build.process

          expect(error_collector.errors[2]).to eq(phony_error: ["Phony Error"])
          expect(error_collector.errors[3]).to eq(phony_error: ["Phony Error"])
        end

        it 'does not collect errors on rows where there are none' do
          CsvPiper::Builder.new.from(file).with_processors([error_collector]).build.process

          expect(error_collector.errors).to be_empty
        end
      end
    end

    describe 'skip processing' do
      let(:file) do
        CsvPiper::TestSupport::CsvMockFile.create(['Row']) do |f|
          f.add({'Row' => 2}) ; f.add({'Row' => 3}) ; f.add({'Row' => 4}) ; f.add({'Row' => 5})
        end
      end

      it 'skips processing a row when nil returned from procesor' do
        CsvPiper::Builder.new.from(file)
          .with_processors([
            CsvImportTestUtils::FlexiProcessors::SkipRows.new([3,4]),
            CsvImportTestUtils::Processors::PassThrough.new,
            output_collector])
          .build.process

        expect(output_collector.output).to eq([{'Row' => '2'},{'Row' => '5'}])
      end

      it 'skips processing a row when nil returned from pre procesor' do
        CsvPiper::Builder.new.from(file)
          .with_pre_processors([CsvImportTestUtils::FlexiProcessors::SkipRows.new([3,4])])
          .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector])
          .build.process

        expect(output_collector.output).to eq([{'Row' => '2'},{'Row' => '5'}])
      end
    end

    describe 'processors' do
      let(:basic_csv_row_downcased) { { "Attr 1" => 'value 1', "Attr 2" => 'value 2' } }
      it 'passes through processors' do
        file = CsvPiper::TestSupport::CsvMockFile.create(basic_headers) do |f|
          f.add(basic_csv_row)
        end

        CsvPiper::Builder.new.from(file)
          .with_processors([
            CsvImportTestUtils::Processors::PassThrough.new,
            CsvImportTestUtils::FlexiProcessors::Error.new("Phony Error"),
            CsvImportTestUtils::Processors::DownCase.new, output_collector, error_collector])
          .build.process

        expect(output_collector.output).to eq([basic_csv_row_downcased])
        expect(error_collector.errors[2]).to eq(phony_error: ["Phony Error"])
      end
    end

    describe 'pre processors' do
      let(:basic_csv_row_upcased) { { "Attr 1" => 'VALUE 1', "Attr 2" => 'VALUE 2' } }
      it 'passes through to regular processors' do
        file = CsvPiper::TestSupport::CsvMockFile.create(basic_headers) do |f|
          f.add( basic_csv_row )
        end

        CsvPiper::Builder.new.from(file)
          .with_pre_processors([
            CsvImportTestUtils::FlexiProcessors::Error.new("Phony Error"),
            CsvImportTestUtils::PreProcessors::UpCase.new])
          .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector, error_collector])
          .build.process

        expect(output_collector.output).to eq([basic_csv_row_upcased])
        expect(error_collector.errors[2]).to eq(phony_error: ["Phony Error"])
      end
    end

    describe 'skip empty rows' do
      let(:file) do
        CsvPiper::TestSupport::CsvMockFile.create(basic_headers,separator) do |f|
          f.add( basic_csv_row )
          f.add( basic_csv_row.each_with_object({}) { |(k, _), memo| memo[k] = '' } )
          f.add( basic_csv_row )
        end
      end

      describe 'with default separator' do
        let(:separator) { ',' }
        it 'skips' do
          CsvPiper::Builder.new.from(file)
            .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector])
            .build.process

          expect(output_collector.output).to eq([basic_csv_row, basic_csv_row])
        end
      end

      describe 'with different separators' do
        let(:separator) { ';' }
        it 'skips' do
          CsvPiper::Builder.new.from(file).with_csv_options(col_sep: separator)
            .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector])
            .build.process

          expect(output_collector.output).to eq([basic_csv_row, basic_csv_row])
        end
      end
    end

    describe 'csv options' do
      it 'converts strings to primitives' do
        file = CsvPiper::TestSupport::CsvMockFile.create(%w(Int Float)) do |f|
          f.add( 'Int' => '12', 'Float' => '99.99' )
        end

        CsvPiper::Builder.new.from(file).with_csv_options(converters: [:numeric])
          .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector])
          .build.process

        expect(output_collector.output).to eq([{"Int" => 12, "Float" => 99.99}])
      end

      it "handles fields being quoted" do
        attrs = { 'Comma Values' => '"Words, with, commas"' }
        expected_attrs = { 'Comma Values' => 'Words, with, commas' }

        file = CsvPiper::TestSupport::CsvMockFile.create(['Comma Values']) do |f|
          f.add( attrs )
        end

        CsvPiper::Builder.new.from(file)
          .with_processors([CsvImportTestUtils::Processors::PassThrough.new, output_collector])
          .build.process

        expect(output_collector.output).to eq([expected_attrs])
      end
    end
  end

  describe 'file setup is invalid' do
    describe 'required setup parameters' do
      it 'requires a file to process from' do
        expect { CsvPiper::Builder.new.build.process }.to raise_error RuntimeError
      end
    end
  end

  describe 'required headers' do
    let(:file) { CsvPiper::TestSupport::CsvMockFile.create(['Bla']) }

    context 'no headers required' do
      it 'has no errors' do
        processer = CsvPiper::Builder.new.from(file).build
        expect(processer.has_required_headers?).to be(true)
        expect(processer.missing_headers).to eq([])
      end
    end

    context 'with required headers' do
      context 'present' do
        it 'has no errors' do
          processer = CsvPiper::Builder.new.from(file).requires_headers(['Bla']).build
          expect(processer.has_required_headers?).to be(true)
          expect(processer.missing_headers).to eq([])
        end
      end

      context 'missing' do
        it 'returns header errors' do
          processer = CsvPiper::Builder.new.from(file).requires_headers(['Me', 'You']).build
          expect(processer.has_required_headers?).to be(false)
          expect(processer.missing_headers).to eq(['Me', 'You'])
        end

        it 'raises exception when trying to process' do
          expect { CsvPiper::Builder.new.from(file).requires_headers(['Me', 'You']).build.process }.to raise_error RuntimeError
        end
      end
    end
  end
end
