#!/usr/bin/ruby

class Torrent
  
  # System constants
  Root_storage_dir = "/mnt/gamma.beta/"
  Root_dl_dir = "/home/andy/file.sharing/"

  # Other constants
  Movie_edition = "UNRATED|PROPER|LIMITED|Unrated"
  Movie_source = "DVDRip|BDRip|R5|\d\d\d\d"
  Movie_extras = "*.nfo *.srt *.jpg Subs"
  
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

    puts `mkdir -p #{dst}`
    puts "unrar e #{rar_path} #{dst}"
    puts `unrar e #{rar_path} #{dst}`
  end

  def tv_show(path)
    # Determine TV show directory path
    path =~ /\A(.+)\.[Ss](\d+)[eE]\d+.*\Z/
    if nil==$1
      path =~ /\A(.+)\.(\d+)x\d+.*\Z/
    end
    name = clean_name($1)
    season_num = $2
    season_num = season_num.to_s.gsub('0', '') # doesn't work with 10, 20,...
    mv_dir = "#{root_storage_dir}tv.shows/#{name}/Season\\ #{season_num}/"

    unrar(full_path, mv_dir)

    # Print summary
    puts "Unrared #{rar_path} to #{mv_dir}"
  end

  def movie(path)
    path =~ /\A(.+)\.(#{movie_edition})*\.(#{movie_source})/
    name = clean_name($1)
    mv_dir = "#{root_storage_dir}movies/#{name}"

    Dir.chdir(full_path)
    cd_paths = Dir.glob("CD*")
    if (!cd_paths.empty?)
      cd_paths.each { |cd_path| unrar(cd_path, mv_dir) }
    else
      unrar(full_path, mv_dir)
    end
    puts `mv #{movie_extras} #{mv_dir}`
  end
  
end

# MAIN
full_path = ARGV[0]
full_path =~ /\A#{root_dl_dir}(.+)\Z/
tracker_dir = $1
tracker_dir =~ /\A([\w\.]*)\/*./
tracker = $1

puts full_path

case tracker
when "public"
  puts "public torrent"
when "super.torrents"
  tracker_dir =~ /\Asuper.torrents\/([\w\.]*)\/(.*)\Z/
  type = $1
  path = $2
  
  case type
  when "tv.shows"
    tv_show(path)
  when "tv.show.packs"
    puts "tv show pack"
  when "movies"
    movie(path)
  else
    puts "other SuperTorrent torrent"
  end
else
  puts "other torrent"
end
