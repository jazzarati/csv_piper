[![Gem Version](https://badge.fury.io/rb/csv_piper.svg)](http://badge.fury.io/rb/csv_piper) [![Build Status](https://travis-ci.org/jazzarati/csv_piper.svg?branch=master)](https://travis-ci.org/jazzarati/csv_piper)

# CsvPiper

A simple wrapper to create a pipeline style csv processor that makes your transforms easily testable.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'csv_piper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install csv_piper

## Usage

CsvPiper handles CSV reading row by row passing each row through a series of processors.

#### Requirements
* Currently source csv must have headers

#### Basic Usage

```ruby
File.open("my/file/path", "r") do |io_stream|
    CsvPiper::Builder.new.from(io_stream).with_processors([your_processors]).build.process
end
```
`io_stream` can be any subclass of [IO](ruby-doc.org/core/IO.html).

`build` returns an instance of `CsvPiper::Piper` but you will only need this object to call `process` unless you are utilising the `requires_headers()` method _(see builder options below)_

#### Basic Usage with Processors
_Extracted from `spec/end_to_end_spec.rb`_

```ruby
# Build some processors beforehand so we can access them later
output_collector = CollectProcessedEquations.new
error_collector = CsvPiper::Processors::CollectErrors.new

# Open the csv file to get our io source
# Csv Data:
# Input 1,Process,Input 2,Result
# 1,+,1,2
File.open(File.join(File.dirname(__FILE__),"/data/csv_1.csv")) do |file|

    # Build piper
    csv_piper = CsvPiper::Builder.new.from(file)
        .requires_headers(required_headers)
        .with_processors([
          BuildEquation.new, EvaluateEquation.new, output_collector, error_collector
        ])
        .build

    # Process csv
    csv_piper.process if csv_piper.has_required_headers?
end

# Grab some output we wanted to collect (You don't have to do this, espicially when processing lots of data)
output = output_collector.output
errors = error_collector.errors


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
```

#### Processors
Each processor can do whatever it wants, transformation, logging, saving to a database etc.

Here is an example of a processor that passes the values from the csv straight along to the transformed output:

```ruby
class PassThrough
  def process(source, transformed, errors)
    [transformed.merge(source), errors]
  end
end
```

* `source` is a frozen hash representing the row data out of the csv (with headers as keys).
* `transformed` is whatever has been passed on by the previous processor. The first processor will receive an empty hash.
* `errors` is an instance of `CsvPiper::Errors::Row`. This is really a convenience object for basic error collecting. You could choose to ignore it and implement your own error handling mechanisms.

If you return `nil` instead of `[transformed, errors]` all further processing of the row will be skipped.

_Return value_ is what will be passed into _transformed_ and _errors_ of the next processor

#### Pre-Processors

Pre-processors work the same as processors except that their purpose is to modify the source row data that will be passed into all processors. It's useful for doing things like converting strings to primitives, removing columns etc.

They are also allowed to add errors against the row.

Here is an example of a pre-processor that converts all values to uppercase:

```ruby
class UpCase
  def process(source, errors)
    transformed = source.each_with_object({}) { |(key, value), memo| memo[key] = value.upcase }
    [transformed, errors]
  end
end
```
* `source` is a hash representing the row data out of the csv which may have been modified by a previous pre-processor
* `errors` is an instance of `CsvPiper::Errors::Row`

If you return `nil` instead of `[transformed, errors]` all further processing of the row will be skipped.

_Return value_ is what will be passed into _source_ and _errors_ of the next pre-processor (and processors). Final pre-processor value of _source_ will be passed to each processor as a frozen hash. Final pre-processor value of _errors_ will be passed to the first processor.

#### Row Errors
This object is passed into each processor (which must pass it on) and is used to accumulate any and all errors for the particular row. You can access the row number through `row_index`.

Add errors using `errors.add(error_key, error)`.

#### Builder Options
All builder options utilise the _fluent interface pattern_ and should be followed by a call to `build` to get the piper instance and then `process` to process the csv.

Eg. `CsvPiper::Builder.new.from(io).with_processors(processors).build.process`

* `from(io_stream)`: Specifies the **open** io stream to read csv data from
* `with_pre_processors(pre_processors)`: Takes an array of pre-processors which will transform each row before it is handled by processors
* `with_processors(processors)`: Takes an array of processors which do all the interesting domain based work
* `with_csv_options(options)`: Takes an options hash which is passed to `CSV.new` to set any options on the CSV library
* `requires_headers(headers)`: Takes an array of strings representing the headers that must be present in the CSV. If this build option is used and `process` is called on a io source missing a header then a exception is thrown. Before calling `process` you should make use of the `has_required_headers?` check and then retrieve the missing headers through `missing_headers` if necessary.

## Pre-made Processors
Over time we will collect a bunch of general purpose processors that anyone can use. They can be found in the `lib/processors` folder but here are a couple:

* `Copy`: Copies or maps key-values from the source row into the transformed object.
* `CollectOutput`: Collects the transformed object of every row that is passed through it.
* `CollectErrors`: Collects the `RowError` object of every row that is passed through it.
* `CreateActiveModel`: Uses the transformed object as attributes and creates using it (Works with ActiveRecord models). Merges errors from model into row errors (Assumes ActiveModel::Errors interface).

By using `CollectOutput` and to a lesser extent `CollectErrors` you will start to build up objects in memory. For very large csv files you might not want to use these convenience processors and rather create a new processor that does whatever you need with the row (Ie. log, write to db) which will then be discarded rather than collected.

Require them explicitly if you want to use them.

Eg. `require 'csv_piper/processors/collect_output'`

## Test Support

There is a CsvMockFile object that you can use to mock up an io csv source rather than working with on disk files for your tests. Just `require 'csv_piper/test_support/csv_mock_file'`.

## Inspiration

Initial inspiration crystalised upon seeing [Kiba](https://github.com/thbar/kiba). If you need to do extensive ETL (particularly if you don't have csv's) then strongly recommend you check it out.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jazzarati/csv_piper.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

