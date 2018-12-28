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

    context 'when there are 3 MTS files named named 00002.MTS, 00003.MTS and 00004.MTS' do

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


  describe 'group video files' do
    context 'when the video_files list is empty' do
      it 'keeps the grouped_video_files empty' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = []
        runner.group_video_files

        expect(runner.grouped_video_files).to be_empty
      end
    end


    context 'when the video_files list has two files of less than two gigabytes' do

      it 'creates one file group for each file' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = [['00002.MTS', 100],['00003.MTS', 1000]]
        runner.group_video_files

        expect(runner.grouped_video_files).to eq({
          1 => ['00002.MTS'],
          2 => ['00003.MTS']
        })
      end

    end

    context 'when the video_files list has two files and the first file has two gigabytes' do

      it 'creates one file group with both files' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = [['00002.MTS', 2040000000],['00003.MTS', 1000]]
        runner.group_video_files

        expect(runner.grouped_video_files).to eq({
          1 => ['00002.MTS', '00003.MTS']
        })
      end

    end

    context 'when the video_files list has two files and the first file has more than two gigabytes' do

      it 'creates one file group with both files' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = [['00002.MTS', 2040000000 + 1000],['00003.MTS', 1000]]
        runner.group_video_files

        expect(runner.grouped_video_files).to eq({
          1 => ['00002.MTS', '00003.MTS']
        })
      end

    end

    context 'when the video_files list has two files and first file and the second file have two gigabytes' do

      it 'creates one file group with both files' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = [['00002.MTS', 2040000000],['00003.MTS', 2040000000]]
        runner.group_video_files

        expect(runner.grouped_video_files).to eq({
          1 => ['00002.MTS', '00003.MTS']
        })
      end

    end

    context 'when the video_files list has three files and the second file has two gigabytes and the other files has less than two gigabytes' do

      it 'creates two file groups, one with the first file and the second with the other files' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = [['00002.MTS', 1000000],['00003.MTS', 2040000000],['00004.MTS', 1500000]]
        runner.group_video_files

        expect(runner.grouped_video_files).to eq({
          1 => ['00002.MTS'],
          2 => ['00003.MTS', '00004.MTS']
        })

      end
    end

    context 'when the video_files list has three files and they all have more than two gigabytes' do

      it 'creates two file groups, one with the first file and the second with the other files' do
        runner = Mts::Autojoin::Runner.new(nil)
        runner.video_files = [['00002.MTS', 2040000000],['00003.MTS', 2040000000],['00004.MTS', 2040000000]]
        runner.group_video_files

        expect(runner.grouped_video_files).to eq({
          1 => ['00002.MTS', '00003.MTS', '00004.MTS']
        })

      end
    end

  end

  describe 'create file lists and execute' do

    context 'when there are two grouped video files' do

      before do
        @runner = Mts::Autojoin::Runner.new(nil)
        @runner.grouped_video_files = {
          1 => ['00002.MTS'],
          2 => ['00003.MTS', '00004.MTS']
        }
      end

      it 'creates a metafile with the first file' do
        allow(Kernel).to receive(:system)
        @runner.create_file_list_and_execute
        file_content = File.read('file-list-1.meta')
        expect(file_content).to eq("file '/00002.MTS'\n")
      end


      it 'creates a metafile with the the other files' do
        allow(Kernel).to receive(:system)
        @runner.create_file_list_and_execute
        file_content = File.read('file-list-2.meta')
        expect(file_content).to eq("file '/00003.MTS'\nfile '/00004.MTS'\n")
      end

      it 'executes the ffmpeg concat command for both metafiles to create two video files' do
        expect(Kernel).to receive(:system).with("ffmpeg -f concat -safe 0 -i file-list-1.meta -c copy video-output-1.mts")
        expect(Kernel).to receive(:system).with("ffmpeg -f concat -safe 0 -i file-list-2.meta -c copy video-output-2.mts")
        @runner.create_file_list_and_execute
      end


      after do
        File.delete('file-list-1.meta')
        File.delete('file-list-2.meta')
      end

    end

  end

end
