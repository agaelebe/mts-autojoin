require 'fileutils'
require 'securerandom'

RSpec.describe Mts::Autojoin do
  it 'has a version number' do
    expect(Mts::Autojoin::VERSION).not_to be '0.1.3'
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

    context 'when the received path is a valid folder' do
      before do
        @valid_path = 'valid'
        FileUtils.rmtree(@valid_path)
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

  describe 'check video files in a valid folder' do

    before do
      @valid_path = 'valid'
      FileUtils.rmtree(@valid_path)
      Dir.mkdir(@valid_path)
    end

    context 'when there are no MTS files' do
      it 'aborts the program saying no MTS files where found' do
        runner = Mts::Autojoin::Runner.new(@valid_path)

        expect { runner.check_video_files }.to raise_error(SystemExit) do |error|
          expanded_path = File.expand_path(@valid_path)
          expect(error.message).to eq("No MTS files found at '#{expanded_path}'")
        end
      end
    end

    context 'when there is one mts file named BLA.MTS' do

      before do
        @video_filename = 'BLA.MTS'
        FileUtils.touch(@valid_path + '/' + @video_filename)
      end

      it 'is added to the video files list with name and file size' do
        runner = Mts::Autojoin::Runner.new(@valid_path)
        runner.check_video_files

        expect(runner.video_files).to include([@video_filename, 0])
      end

      after do
        FileUtils.rm(@valid_path + '/' + @video_filename)
      end

    end


    context 'when there is one mts file named 00001.mts with 1024 bytes' do

      before do
        @one_kilobyte = 1024
        @video_filename =  '00001.MTS'
        @file_path = File.join(@valid_path, @video_filename)
        FileUtils.touch(@file_path)

        @file = File.open(@file_path, 'wb') do |f|
          @one_kilobyte.times { f.write( 0 ) }
        end
      end

      it 'adds the file to the video_files list with its name and file size' do
        runner = Mts::Autojoin::Runner.new(@valid_path)
        runner.check_video_files

        expect(runner.video_files).to include([@video_filename, @one_kilobyte])
      end

      after do
        FileUtils.rm(@file_path)
      end

    end

    context 'when there are 3 mts files named named 00002.mts, 00003.mts and 00004.mts' do

      before do
        @video_filenames = ['00002.MTS', '00003.MTS', '00004.MTS']

        @video_filenames.each do |filename|
          FileUtils.rmtree(@valid_path + '/' + filename)
          FileUtils.touch(@valid_path + '/' + filename)
        end
      end

      it 'adds the files to the video_files list with their names, file sizes and in ascending order' do
        runner = Mts::Autojoin::Runner.new(@valid_path)
        runner.check_video_files

        expect(runner.video_files).to eq([['00002.MTS', 0],['00003.MTS',0], ['00004.MTS',0]])
      end

      after do
        @video_filenames.each do |filename|
          FileUtils.rmtree(@valid_path + '/' + filename)
        end
      end

    end

    after do
      FileUtils.rmtree(@valid_path)
    end

  end

end
