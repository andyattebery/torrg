class Tracker
  def self.new(full_torrent_path = nil)
    @full_path = full_torrent_path
    tracker = get_tracker()
    klass = case tracker
      when 'bit.hdtv' then BitHDTV
      when 'super.torrents' then SuperTorrents
      when 'what.cd' then WhatCD
      when 'public' then Public
    end
    
    klass == self ? super() : klass.new(@full_path)
  end
    
  def process
    raise NotImplementedError
  end
  
  private
  def get_tracker
    @full_path =~ /\A#{Root_dl_dir}(.+)\Z/
    @tracker_path = $1
    @tracker_path =~ /\A([\w\.]*)\/*./
    @tracker = $1
    @tracker_dir =~ /\A#{@tracker}\/([\w\.]*)\/(.*)\Z/
    @torrent_type = $1
    @torrent_name = $2
    @tracker
  end
end

class BitHDTV < Tracker
  def self.new(torrent_path)
    puts "New BitHDTV tracker: #{torrent_path}"
    super
  end
  
  class BitHDTVTorrent < Torrent
    def self.new(name, type)
      klass = case type
        when 'tv.shows' then TVShow
        when 'tv.show.packs' then TVShowPack
        when 'movies' then Movie
      end
      klass == self ? super() : klass.new(name, type)
    end
  end
  
  def process
    BitHDTVTorrent.new(@torrent_name, @torrent_type).process
  end
end

class SuperTorrents < Tracker
  def self.new(torrent_path)
    puts "New SuperTorrents tracker: #{torrent_path}"
    super
  end
  
  class SuperTorrentsTorrent < Torrent
    def self.new(name, type)
      klass = case type
        when 'tv.shows' then TVShow
        when 'tv.show.packs' then TVShowPack
        when 'movies' then Movie
      end
      klass == self ? super() : klass.new(name, type)
    end
  end
  
  def process
    case type
    SuperTorrentsTorrent.new(@torrent_name, @torrent_type).process
  end
end

class WhatCD < Tracker
  def self.new(torrent_path)
    puts "New What.cd tracker: #{torrent_path}"
    super
  end
  
  class BitHDTVTorrent < Torrent
    def self.new(name, type)
      klass = case type
        when 'tv.shows' then TVShow
        when 'tv.show.packs' then TVShowPack
        when 'movies' then Movie
      end
      klass == self ? super() : klass.new(name, type)
    end
  end
  
  def process
    BitHDTVTorrent.new(@torrent_name, @torrent_type).process
  end
end

class Public < Tracker
  def self.new(torrent_path)
    puts "New Public tracker: #{torrent_path}"
    super
  end
  
  class BitHDTVTorrent < Torrent
    def self.new(name, type)
      klass = case type
        when 'tv.shows' then TVShow
        when 'tv.show.packs' then TVShowPack
        when 'movies' then Movie
      end
      klass == self ? super() : klass.new(name, type)
    end
  end
  
  def process
    BitHDTVTorrent.new(@torrent_name, @torrent_type).process
  end
end