require 'spec_helper'
require 'active_record'

describe CsvPiper::Processors::CreateActiveModel do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      :adapter  => 'sqlite3',
      :database => ':memory:'
    )

    ActiveRecord::Schema.define do
      unless ActiveRecord::Base.connection.tables.include? 'movies'
        create_table :movies do |table|
          table.column :title, :string, null: false
          table.column :review, :string, null: false
        end
      end
    end
  end

  after do
    Movie.delete_all
  end

  class Movie < ActiveRecord::Base
    validates :title, presence: true
    validate :validate_review

    def validate_review # Force some test errors
      if review? && review != '+1'
        errors.add(:review, 'Must be positive')
        errors.add(:review, 'Must be +1')
        false
      end
    end
  end

  let(:no_errors) { CsvPiper::Errors::Row.new(1) }
  let(:has_errors) do
    errors = CsvPiper::Errors::Row.new(1)
    errors.add(:review, 'row error')
    errors
  end
  let(:title) { 'Avengers' }
  let(:model_attrs)  { { 'title' => title, 'review' => '+1' } }
  let(:transformed_in) { model_attrs.dup }
  let(:invalid_model_attrs)  { { 'review' => 'Horrible' } }

  context 'no row errors' do
    context 'without model errors' do
      it 'saves model' do
        described_class.new(Movie).process({}, transformed_in, no_errors)
        expect(Movie.find_by_title(title).attributes.except('id')).to eq(model_attrs)
      end

      it 'passes on inputs with the model' do
        transformed, errors = described_class.new(Movie).process({}, transformed_in, no_errors)

        expect(transformed.except(:movie_model)).to eq(model_attrs)
        expect(transformed[:movie_model].attributes.except('id')).to eq(model_attrs)
        expect(errors).to be(no_errors)
      end
    end

    context 'with model errors' do
      it 'does not save model' do
        _, errors = described_class.new(Movie).process({}, invalid_model_attrs, no_errors)
        expect(errors.errors).to eq( title: ["can't be blank"], review: ["Must be positive", "Must be +1"])
        expect(Movie.count).to eq(0)
      end

      it 'passes on inputs with the model' do
        transformed, _ = described_class.new(Movie).process({}, transformed_in, no_errors)

        expect(transformed.except(:movie_model)).to eq(model_attrs)
        expect(transformed[:movie_model].attributes.except('id')).to eq(model_attrs)
      end
    end
  end

  context 'with existing row errors' do
    context 'without model errors' do
      it 'does not save model' do
        _, errors = described_class.new(Movie).process({}, model_attrs, has_errors)
        expect(errors.errors).to eq(review: ['row error'])
        expect(Movie.count).to eq(0)
      end
    end

    context 'with model errors' do
      it 'combines existing errors and active record errors' do
        _, errors = described_class.new(Movie).process({}, invalid_model_attrs, has_errors)
        expect(errors.errors).to eq( title: ["can't be blank"], review: ["row error", "Must be positive", "Must be +1"])
        expect(Movie.count).to eq(0)
      end
    end
  end
end
