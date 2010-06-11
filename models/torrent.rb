class Torrent
  def self.new(path)
    @path = path
    klass = case determine_type
      when 'birp' then BirpTorrent
      when 'lossless' then LosslessTorrent
      when 'lossy' then LossyTorrent
      when 'misc' then MiscTorrent
      when 'movies' then MovieTorrent
      when 'promo.only' then PromoOnlyTorrent
      when 'tv.shows' then TVShowTorrent
      when 'tv.show.packs' then TVShowPackTorrent
    end
    klass == self ? super() : klass.new(path)
  end
  
  def organize
    raise NotImplementedError
  end
  
  private
  def determine_type
    @path =~ /\A#{Root_dl_dir}(.+)\Z/
    tracker_path = $1
    tracker_path =~ /\A([\w\.]*)\/*./
    @tracker = $1
    tracker_path =~ /\A#{@tracker}\/([\w\.]*)\/(.*)\Z/
    @type = $1
    @name = $2
  end
  
  def clean_title(title)
    title = title.gsub(/\b\w/) { $&.upcase }
    title = title.gsub('.', '\ ')
    title = title.gsub('_', '\ ')
    title
  end
  
  def unrar(src, dst)
    rar_path = `find #{src} -type f -name '*.rar'`
    if(rar_path.to_s.match("part01"))
      rar_path =~ /(.+\.part01.rar)/
      rar_path = $1
    end
    rar_path = rar_path.chomp
    cmd = "unrar e #{path}/#{name} #{path}"
    puts cmd
    system(cmd)
  end
end

class BirpTorrent < Torrent
  def self.new(path)
    puts "New Birp torrent: #{path}"
    super
  end
    
  def organize
    
  end
end

class LosslessTorrent < Torrent
  def self.new(path)
    puts "New Lossless torrent: #{path}"
    super
  end
    
  def organize
    
  end
end

class LossyTorrent < Torrent
  def self.new(path)
    puts "New Lossy torrent: #{path}"
    super
  end
    
  def organize
    
  end
end

class MiscTorrent < Torrent
  def self.new(path)
    puts "New Misc torrent: #{path}"
    super
  end
    
  def organize
    
  end
end

class MovieTorrent < Torrent
  def self.new(path)
    puts "New Movie torrent: #{path}"
    super
  end
    
  def organize
    @name =~ /\A([\w\.]*)\.(\d{4}\.)?(#{Movie_edition}|#{Movie_source})*/i
  	@title = clean_title($1)
    mv_dir = "#{Root_storage_dir}movies/standard.def/#{@title}"
    puts `mkdir -p #{mv_dir}`
    

    puts `mv #{movie_extras} #{mv_dir}`
    puts `ln -s #{mv_dir}/#{movie_extras}`
  end
  
  private
  def unrar_cds
    Dir.chdir(@path)
    cd_paths = Dir.glob("CD*")
    if (!cd_paths.empty?)
      cd_paths.each do |cd_path|
        unrar(cd_path, mv_dir)
      end
    else
      unrar(path, mv_dir)
    end
  end
end

class PromoOnlyTorrent < Torrent
  def self.new(path)
    puts "New PromoOnly torrent: #{path}"
    super
  end
    
  def organize
    
  end
end

class TVShowTorrent < Torrent
  def self.new(path)
    puts "New TVShow torrent: #{path}"
    super
  end
    
  def organize
    @name =~ /\A(.+)\.[Ss](\d+)[eE]\d+.*\Z/
    if nil==$1
      @name =~ /\A(.+)\.(\d+)x\d+.*\Z/
    end
    @title = clean_title($1)
    @season_num = $2
    # TODO: Find out if it is .rar's or an .avi or .mkv
    mv_dir = "#{Root_storage_dir}tv.shows/standard.def/#{@title}/Season\\ #{@season_num}/"
  end
end

class TVShowPackTorrent < Torrent
  def self.new(path)
    puts "New TVShowPack torrent: #{path}"
    super
  end
    
  def organize
    
  end
end
