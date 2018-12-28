require "mts/autojoin/version"
require "tempfile"

module Mts
  module Autojoin
    class Runner

      TWO_GIGABYTES = 2040000000
      FOUR_GIGABYTES = 4172000000

      attr_accessor :full_path, :video_files, :grouped_video_files
      attr_reader :max_file_size

      def initialize(path)
        @full_path = File.expand_path(path || '/')
        @video_files = []
        @max_file_size = TWO_GIGABYTES
        @grouped_video_files = Hash.new { |h,k| h[k] = [] }
      end

      def check_folder
        if File.directory?(full_path)
          puts "MTS files will be checked at '#{full_path}'"
        else
          abort 'You did not provide a valid folder'
        end
      end

      def check_video_files
        Dir.entries(full_path).sort.each do |file|
          next if (file == '.' || file == '..' || !['.mts','.MTS'].include?(File.extname(file)))
          @video_files << [file, File.size(File.expand_path(file, full_path))]
        end
        abort "No MTS files found at '#{full_path}'" if @video_files.empty?
      end

      # Update max_file_size to FOUR_GIGABYTES if there is at least one file
      # equal or greather than 4 gigabytes
      def set_max_file_size
        @video_files.each do |file, size|
          if size >= FOUR_GIGABYTES
            @max_file_size = FOUR_GIGABYTES
            break
          end
        end
      end

      def group_video_files
        current_filegroup = 1

        @video_files.each do |file, size|
          @grouped_video_files[current_filegroup] += [file]
          if size < max_file_size
            current_filegroup += 1
          end
        end

        @grouped_video_files
      end


      def create_file_list_and_execute
        @grouped_video_files.each do |group_number, filenames|
          File.open("file-list-#{group_number}.meta","w") do |tmpfile|
            filenames.each do |filename|
              tmpfile.puts("file '" + File.expand_path(filename, full_path) + "'")
            end
          end
          execute_concat_command("file-list-#{group_number}.meta", group_number)
        end
      end

      def execute_concat_command(file, number)
        Kernel.system "ffmpeg -f concat -safe 0 -i #{file} -c copy video-output-#{number}.mts"
      end

      def delete_metafiles
        Dir.glob('*.meta').each { |f| File.delete(f) }
      end

      def run!
        check_folder
        check_video_files
        set_max_file_size
        group_video_files
        create_file_list_and_execute
        delete_metafiles
      end

    end
  end
end
