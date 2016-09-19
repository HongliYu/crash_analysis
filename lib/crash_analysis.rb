require "crash_analysis/version"

# Main
module CrashAnalysis

  def initialize()
  end

  def self.run()
  puts "input logs_dir_path: "
    logs_dir_path = gets.chomp
  if logs_dir_path.empty? || logs_dir_path.nil? || !File.directory?(logs_dir_path)
    puts "invalid logs_dir_path"
    return
  end
  puts "input log_file_suffix(log, crash, txt etc.): "
    log_file_suffix = gets.chomp
  if log_file_suffix.empty? || log_file_suffix.nil?
    puts "invalid log_file_suffix"
    return
  end

  puts "init settings..."
  output = []
  r, io = IO.pipe
  fork do
    system("find /Applications/Xcode.app -name symbolicatecrash -type f", out: io, err: :out)
  end
  io.close
  r.each_line{|l| puts l; output << l.chomp}
  symbolicatecrash_path = output[0]

  puts "running..."
  analysis = Analysis.new()
  analysis.run(logs_dir_path, log_file_suffix, symbolicatecrash_path)

  end

  class Analysis

    def initialize()
      @dSYM_file_name = ""
    end

    def run(logs_dir_path, log_file_suffix, symbolicatecrash_path)
      crash_files = traverse(logs_dir_path, log_file_suffix)
      analysis_action(crash_files, log_file_suffix, logs_dir_path, symbolicatecrash_path)
    end

    def traverse(logs_dir_path, log_file_suffix)
      crash_files = Array.new
      count_app = 0
      count_dSYM = 0

      Dir.foreach(logs_dir_path) do |file|
        file_suffix_array = file.strip.split(".")
        if file_suffix_array.last == log_file_suffix
          file_suffix_array.pop
          crash_files << (file)
        end
        if file_suffix_array.last == "app"
          count_app += 1
        end
        if file_suffix_array.last == "dSYM"
          @dSYM_file_name = file
          count_dSYM += 1
        end
      end

      if count_app != 1 || count_dSYM !=1 || crash_files.count < 1
          puts "error:\n"
          puts "make sure the directory contains those files: 1 .app file & 1 .dSYM file & related crash files"
        return
      end
      return crash_files
    end

    def analysis_action(crash_files, log_file_suffix, logs_dir_path, symbolicatecrash_path)
      evn = "export DEVELOPER_DIR='/Applications/XCode.app/Contents/Developer'"
      output_log_dir = logs_dir_path + "/crash_logs"
      percent_count = 0
      if !File.directory?(output_log_dir)
        Dir.mkdir(output_log_dir)
      end

      for file in crash_files
        running_thread = Thread.new do
          short_file_name = file.split("/").last

          output_file = output_log_dir + "/" + short_file_name
          current_log_file = logs_dir_path + "/" + file
          system("#{evn} \n #{symbolicatecrash_path} #{current_log_file} #{@dSYM_file_name} > #{output_file}")
          
          percent_count = percent_count + 1
          precent = ((percent_count.to_f / crash_files.count.to_f) * 10000).round / 10000.0
          str = (precent * 100).to_s
          puts "#{str[0,4]}% || analyzing file: #{file}"
          Thread.main.wakeup
        end
        # Maximum run for 10 seconds
        sleep 10
        Thread.kill(running_thread)
      end
      puts "\n Done."
    end

  end
  
end
