require 'singleton'
require File.expand_path('../torrent', __FILE__)

class MusicTorrentFactory
  include Singleton
  
  def create_torrent(file_path, torrent_path)
    Dir.chdir(file_path)
    if Dir.glob("*.flac").any?
       return MusicFlacTorrent.new(file_path, torrent_path)
    elsif Dir.glob("*.mp3").any? && file_path =~ /mainstream.radio/i
      return MusicPromoOnlyTorrent.new(file_path, torrent_path)
    end
    
    Dir.glob("*").each do |f| 
      if File.directory?(f) then create_torrent.new(f, torrent_path).organize end
    end
  end
end

class TorrentFactory
  include Singleton
  
  def create_torrent(file_path, torrent_path)
    if file_path =~ /movie/
      # return MovieTorrent.new(file_path, torrent_path)
    elsif torrent_path =~ /music/
      # return MusicTorrentFactory.instance.create_torrent(file_path, torrent_path)
    elsif file_path =~ /tv.show/
      return TVShowTorrent.new(file_path, torrent_path)
    else raise "Not movie, music, or tv.show"
    end
  end
end