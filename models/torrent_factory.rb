require 'singleton'
require File.expand_path('../torrent', __FILE__)

class TorrentFactory
  include Singleton
  
  def create_torrent(path, torrent)
    path =~ /^#{DOWNLOAD_DIR}\/[\w\.]*\/([\w\.]*)/
    case $1
    when "music" then return MusicTorrent.new(path, torrent)
    when "tv.show" then return TVShowTorrent.new(path, torrent)
    when "movie" then return MovieTorrent.new(path, torrent)
    else raise "Unknown torrent type: #{$1}"
    end
  end
end