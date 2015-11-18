require "crash_analysis/version"

def traverse(filePath)
  crashFileNames = Array.new
  if File.directory?(filePath)
    Dir.foreach(filePath) do |fileName|
      fileSuffixArray = fileName.strip.split(".")
      if fileSuffixArray.last == "crash"
        fileSuffixArray.pop
        crashFileNames << (filePath + "/" + fileSuffixArray.first)
      end
    end
  else
    puts "Files:" + filePath
  end
  return crashFileNames
end

def AnalysisLog(crashFileNames)
  cmd = "/Applications/Xcode.app/Contents/SharedFrameworks/DTDeviceKitBase.framework/Versions/A/Resources/symbolicatecrash"
  evn = "export DEVELOPER_DIR='/Applications/XCode.app/Contents/Developer'"
  crashFileNames.prog_each {
   |fileName|
    system("#{evn} \n #{cmd} #{fileName}.crash BDPhoneBrowser.app.dSYM > #{fileName}.log")
  }
end

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

module CrashAnalysis
  def self.run(filePath)
    system("echo running...")
    if File.directory?(filePath)
      crashFileNames = traverse(filePath)
      AnalysisLog(crashFileNames)
    else
      puts "error: not a directory"
    end
  end
end
