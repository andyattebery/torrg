require 'singleton'
require File.expand_path('../action', __FILE__)

class ActionFactory
  include Singleton
  
  def create_action(file_path, dst_dir)
    if Dir.glob("*.rar").any?
      return UnrarAction.new(file_path, dst_dir)
    # Checks for video file ignoring sample videos
    elsif (Dir.glob("*.{avi,mkv}").delete_if { |f| f.downcase.include? "sample" }).any?
      return MoveAction.new(file_path, dst_dir)
    elsif (dirs = Dir.glob("*").select { |f| File.directory?(f) }).any?
      dirs.each do |f| 
        Torrent.new(File.expand_path(f), "")
      end
    else
      puts "No .rar, .avi, or .mkv files or directories where found..."
    end
  end
end


def unrar_cds
  Dir.chdir(@file_path)
  cd_paths = Dir.glob("CD*")
  if (!cd_paths.empty?)
    cd_paths.each do |cd_path|
      unrar(cd_path, mv_dir)
    end
  else
    unrar(path, mv_dir)
  end
end