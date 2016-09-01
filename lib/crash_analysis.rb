require "crash_analysis/version"

# Utils
class Array
  def prog_each(&block) 
    bar_length = (`tput cols` || 80).to_i - 30
    time_now = Time.now
    total = self.count
    last_flush = 0
    flush_time = 1
    self.each_with_index{|element, x|
      cur = (x + 1) * 100 / total
      time_left = (((Time.now - time_now) * (100 - cur)).to_f / cur).ceil
      if (Time.now - last_flush).to_i >= flush_time or time_left < 1
        time_left_graceful = Time.at(time_left).utc.strftime("%H:%M:%S")
        if time_left > 86400
          time_left_graceful = res.split(":")
          time_left_graceful[0] = (time_left_graceful[0].to_i + days * 24).to_s
          time_left_graceful = time_left_graceful.join(":")
        end
        print "\r"
        cur_len = (bar_length * (x + 1)) / total
        print "[" << (["#"] * cur_len).join << (["-"] * (bar_length - cur_len)).join << "] #{cur}% [#{time_left_graceful} left]"
        last_flush = Time.now
      end
      block.call element if block
    }
    puts "\n"
    "Done."
  end
end

# Main
module CrashAnalysis
  Version = "0.1.3"
  def self.run(filePath, rawFileSuffix)
    puts "running..."
    analysis = Analysis.new()
    analysis.run(filePath, rawFileSuffix)
  end

  class Analysis

    def initialize()
      @percentCount = 0
    end

    def run(filePath, rawFileSuffix)
      if rawFileSuffix.nil? || rawFileSuffix.empty?
          puts "error: need 2 arguments DirPath & raw log file suffix like:txt, log, crash..."
          return
        end
        if filePath.nil? || filePath.empty?
          puts "error: need directory path"
        else
          if File.directory?(filePath)
            crashFileNames = traverse(filePath, rawFileSuffix)
            if crashFileNames.nil? || crashFileNames.empty?
              return
            else
               AnalysisLog(crashFileNames, rawFileSuffix, filePath)
            end
          else
            puts "error: not a directory"
          end
        end
    end

    def traverse(filePath, rawFileSuffix)
    crashFileNames = Array.new
    countApp = 0
    countDSYM = 0
    if File.directory?(filePath)
      Dir.foreach(filePath) do |fileName|
        fileSuffixArray = fileName.strip.split(".")
        if fileSuffixArray.last == rawFileSuffix
          fileSuffixArray.pop
          crashFileNames << (filePath + "/" + fileSuffixArray.first)
        end
        if fileSuffixArray.last == "app"
          countApp += 1
        end
        if fileSuffixArray.last == "dSYM"
          countDSYM += 1
        end
      end
    else
      puts "Files:" + filePath
    end

    if countApp != 1 || countDSYM !=1 || crashFileNames.count < 1
        puts "error:\n"
        puts "make sure the directory contains those files: one .app file & one .dSYM file & related crash files"
      return
    end

    return crashFileNames
  end

    def AnalysisLog(crashFileNames, rawFileSuffix, filePath)
      cmd = "/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash"
      evn = "export DEVELOPER_DIR='/Applications/XCode.app/Contents/Developer'"
      logDir = filePath + "/crash_logs"

      if !File.directory?(logDir)
        Dir.mkdir(logDir)
      end

      for fileName in crashFileNames
        runningThread = Thread.new do
          shortFileName = fileName.split("/").last
          outputFile = logDir + "/" + shortFileName +".log"
          system("#{evn} \n #{cmd} #{fileName}.#{rawFileSuffix} BDPhoneBrowser.app.dSYM > #{outputFile}")
          @percentCount = @percentCount + 1
          precent = ((@percentCount.to_f / crashFileNames.count.to_f) * 10000).round / 10000.0
          str = (precent * 100).to_s
          print "\r #{str[0,4]}%"
          Thread.main.wakeup
        end
        # Maximum run for 10 seconds
        sleep 10
        Thread.kill(runningThread)
      end
      puts "\n Done."
    end
  end
end
