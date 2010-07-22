require 'fileutils'

class Action
  def initialize(files, dst_dir)
    @files = files
    @dst_dir = dst_dir
  end
  
  def execute()
    NotImplementedError
  end
end

class UnrarAction < Action
  def initialize(files, dst_dir)
    super(files, dst_dir)
    @rar_file = (f = Dir.glob("*.part01.rar")).any? ? f : Dir.glob("*.rar")
    @files.delete_if { |f| f =~ /\.r[a\d][r\d]$/ }
  end
  
  def execute
    if !File.exists?(@dst_dir) then FileUtils.mkdir_p(@dst_dir) end
    system("unrar e #{@rar_file} #{@dst_dir}")
    FileUtils.cp_r(@files, @dst_dir)
  end
end

class MoveAction < Action
  def initialize(files, dst_dir)
    super(files, dst_dir)
  end
  
  def execute
    if !File.exists?(@dst_dir) then FileUtils.mkdir_p(@dst_dir) end
    src_dir = Dir.pwd
    FileUtils.cp_r(@files, @dst_dir)
    FileUtils.rm_r(@files)
    Dir.chdir(@dst_dir)
    FileUtils.ln_s(@files, src_dir)
  end
end