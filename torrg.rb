#!/usr/bin/ruby

# System constants
root_storage_dir = "/mnt/gamma.beta/"
root_dl_dir = "/home/andy/file.sharing/"

# Other constants
movie_extras = "*.nfo *.srt *.jpg Subs"

# Helper functions
def clean_name(name)
  name = name.gsub(/\b\w/) { $&.upcase }
  name = name.to_s
  name = name.gsub('.', '\ ')
  name = name.gsub('_', '\ ')
  return name
end

def unrar(src, dst)
  rar_path = `find #{src} -type f -name '*.rar'`
  if(rar_path.to_s.match("part01"))
    rar_path =~ /(.+\.part01.rar)/
    rar_path = $1
  end
  rar_path = rar_path.chomp
  
  puts "unrar e #{rar_path} #{dst}"
  puts `unrar e #{rar_path} #{dst}`
end  

full_path = ARGV[0]
puts "full path: #{full_path}"

full_path =~ /\A#{root_dl_dir}(.+)\Z/
tracker_dir = $1
tracker_dir =~ /\A([\w\.]*)\/*./
tracker = $1

case tracker
when "public"
  puts "public torrent"
when "super.torrents"
  tracker_dir =~ /\Asuper.torrents\/([\w\.]*)\/(.*)\Z/
  type = $1
  path = $2
  puts "path: #{path}"
  
  case type
  when "tv.shows"
    # Determine rar path
    rar_path = `find #{full_path} -type f -name '*.rar'`
    if(rar_path.to_s.match("part01"))
      rar_path =~ /(.+\.part01.rar)/
      rar_path = $1
    end
    rar_path = rar_path.chomp

    # Determine TV show directory path
    path =~ /\A(.+)\.[Ss](\d+)[eE]\d+.*\Z/
    if nil==$1
      path =~ /\A(.+)\.(\d+)x\d+.*\Z/
    end
    name = $1
    season_num = $2
    name = name.gsub(/\b\w/) { $&.upcase }
    name = name.to_s
    name = name.gsub('.', '\ ')
    name = name.gsub('_', '\ ')
    season_num = season_num.to_s.gsub('0', '') # doesn't work with 10, 20,...
    mv_dir = "#{root_storage_dir}tv.shows/standard.def/#{name}/Season\\ #{season_num}/"
    puts `mkdir -p #{mv_dir}`

    # Unrar file
    puts "unrar e #{rar_path} #{mv_dir}"
    puts `unrar e #{rar_path} #{mv_dir}`

    # Print summary
    puts "Unrared #{rar_path} to #{mv_dir}"
  when "tv.show.packs"
    puts "tv show pack"
  when "movies"
      path =~ /\A(.+)\.(\d{4}|DVDRip|BDRip|R5|UNRATED|LIMITED|PROPER|REPACK|TELESYNC)/
      puts $1
	name = clean_name($1)
      mv_dir = "#{root_storage_dir}movies/standard.def/#{name}"
      puts `mkdir -p #{mv_dir}`
      
      Dir.chdir(full_path)
      cd_paths = Dir.glob("CD*")
      if (!cd_paths.empty?)
        cd_paths.each do |cd_path|
          unrar(cd_path, mv_dir)
        end
      else
        unrar(full_path, mv_dir)
      end
      puts `cp -r #{movie_extras} #{mv_dir}`
  else
    puts "other SuperTorrent torrent"
  end
else
  puts "other torrent"
end
