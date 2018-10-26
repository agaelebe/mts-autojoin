require 'fileutils'

RSpec.describe Mts::Autojoin do
  it 'has a version number' do
    expect(Mts::Autojoin::VERSION).not_to be nil
  end

  describe 'check if folder is valid' do
    context 'when the received path does not exist' do
      it 'prints an error message and exits' do
        path = 'invalid'
        runner = Mts::Autojoin::Runner.new(path)
        expect {runner.check_folder}.to raise_error(SystemExit,'You did not provide a valid folder')
      end
    end

    context 'when the received path is a file' do
      before do
        @file = 'file.txt'
        FileUtils.touch(@file)
      end

      it 'prints an error message and exits' do
        runner = Mts::Autojoin::Runner.new(@file)
        expect {runner.check_folder}.to raise_error(SystemExit,'You did not provide a valid folder')
      end

      after do
        File.delete(@file)
      end
    end

    context 'when the received path is a valid directory' do
      before do
        @valid_path = 'valid'
        Dir.mkdir(@valid_path)
      end

      it 'prints a message with the received path expanded' do
        runner = Mts::Autojoin::Runner.new(@valid_path)
        expanded_path = File.expand_path(@valid_path)
        expect{runner.check_folder}.to output("MTS files will be checked at '#{expanded_path}'\n").to_stdout
      end

      after do
        Dir.delete(@valid_path)
      end

    end
  end

end
