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
    torrent_path =~ /\/[^\/]+\/([^\/]+)\/[^\/]+$/
    case $1
    when "music" then return MusicTorrentFactory.instance.create_torrent(file_path, torrent_path)
    when "tv.show" then return TVShowTorrent.new(file_path, torrent_path)
    when "movie" then return MovieTorrent.new(file_path, torrent_path)
    else raise "Unknown torrent type: #{$1}"
    end
  end
end