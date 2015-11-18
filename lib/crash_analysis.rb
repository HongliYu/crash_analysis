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
  for fileName in crashFileNames do
      system("#{evn} \n #{cmd} #{fileName}.crash BDPhoneBrowser.app.dSYM > #{fileName}.log")
  end
end

module CrashAnalysis
  def self.run(filePath)
      puts "Current Dirs:" + filePath
    if File.directory?(filePath)
      crashFileNames = traverse(filePath)
      AnalysisLog(crashFileNames)
    else
      puts "error: not a directory"
    end
  end
end
