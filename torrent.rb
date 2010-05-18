class Torrent
  def self.new(path = nil)
    @path = path
    klass = case get_type()
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
  def get_type
    @path =~ /\A#{Root_dl_dir}(.+)\Z/
    tracker_path = $1
    tracker_path =~ /\A([\w\.]*)\/*./
    @tracker = $1
    tracker_path =~ /\A#{@tracker}\/([\w\.]*)\/(.*)\Z/
    @type = $1
    @name = $2
  end
  
  def clean
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
