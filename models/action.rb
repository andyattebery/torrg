MOVIE_EXTRAS = "*.nfo *.srt *.jpg Subs"

class Action
  def self.new(path)
    klass = determine_class(path)
    puts "file_list[0]: #{@file_list[0]}"
    @@file_path = File.expand_path(@file_list[0])
    klass == self ? super() : klass.new(path)
  end
  
  def execute(dest)
    NotImplementedError
  end
  
  private
  def self.determine_class(path)
    Dir.chdir(File.expand_path(path))
    
    # *.part01.rar must be first check
    if (@file_list = (Dir.glob("**/*.part01.rar"))).any? then return UnrarAction
    elsif (@file_list = (Dir.glob("**/*.rar"))).any? then return UnrarAction
    # Finds video file ignoring sample videos
    elsif (@file_list = (Dir.glob("**/*.{avi,mkv}").delete_if { |f| f.downcase.include? "sample" })).any?
      return MoveAction
    elsif (@file_list = (Dir.glob("**/*").select { |f| File.directory?(f) })).any?
      @file_list.each { |f| Action.new(File.expand_path(f)) }
    # else
    #   puts "No .rar, .avi, or .mkv files where found..."
    end
  end
end

class UnrarAction < Action
  def self.new(path)
    super
  end
  
  def execute(dest)
    system("unrar e #{@file_path} #{dest}")
  end
end

class MoveAction < Action
  def self.new(path)
    super
  end
  
  def execute(dst)
    @@file_path =~ /.*\/(.+)\z/
    file_list = "#{$1}, #{MOVIE_EXTRAS}"
    found_files = Dir.glob("{#{file_list}}")
    src_dir = Dir.pwd
    FileUtils.cp_r(found_files, dst, :verbose => true)
    FileUtils.rm_r(found_files, :verbose => true)
    Dir.chdir(dst)
    FileUtils.ln_s(found_files, src_dir, :verbose => true)
  end
end