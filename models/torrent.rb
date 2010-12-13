require 'net/http'
require 'fileutils'
require 'rubygems'
require 'xmlsimple'
require 'id3lib'

require File.expand_path('../action_factory', __FILE__)

class Torrent

  def initialize(file_path, torrent_path)
    torrent_path =~ /\/([^\/]+)\/([^\/]+)\/([^\/]+)$/
    @tracker = $1
    @type = $2
    @torrent = $3
    
    file_path =~ /^(.*)\/([^\/]+)$/
    @file_name = $2
    @file_dir = File.directory?(file_path) ? file_path : $1 
    Dir.chdir(@file_dir)
  end
  
  def organize
    ActionFactory.instance.create_action(@files, @dst_dir).execute
  end
  
  private
  def clean_title(title)
    title = title.gsub(/\b\w/) { $&.upcase }
    title = title.gsub('.', ' ')
    title = title.gsub('_', ' ')
    title
  end
  
  def fix_track_num(num)
    return 1 == num.length ? "0#{num}" : num
  end
end


class MusicFlacTorrent < Torrent
  def initialize(f, t)
    super(f,t)
    @torrent = @torrent.gsub("amp;", "")
    @torrent =~ /^(.+)\ -\ (.+)\ -\ (\d{4})/
    @artist = $1
    @album = $2
    @year = $3
    @dst_dir = "#{MUSIC_DIR}/Artists/#{@artist[0..0]}/#{@artist}/#{@year} - #{@album}"
    @files = Dir.glob("*.{flac,jpg,m3u,cue,log,nfo}")
  end
end


class MusicPromoOnlyTorrent < Torrent
  def initialize(f, t)
    super(f,t)
    @torrent.downcase =~ /(january|february|march|april|may|june|july|august|september|october|november|december)/
    @month = $1
    @torrent =~ /(\d{4})/
    @year = $1
    @dst_dir = "#{MUSIC_DIR}/Collections/Promo Only Mainstream Radio/" +
            "#{@year} - Promo Only Mainstream Radio/" +
            "#{MONTH_NUMS[@month]} - Promo Only Mainstream Radio [#{@month.capitalize} #{@year}]"
    @files = Dir.glob("*.{mp3,m3u,nfo,jpg}")
  end
end


class TVShowTorrent < Torrent
  def initialize(file_path, torrent_path)
    super(file_path, torrent_path)
    @file_name =~ /^(.+)\.[Ss]?(\d+)x?[Ee]?\d+\./
    @title = clean_title($1)
    @season_num = $2
    @season_num = ("0" == @season_num[0..0]) ? @season_num[1..1] : @season_num
    @dst_dir = "#{TV_SHOW_DIR}/#{@title}/Season #{@season_num}"
    @files = Dir.glob("*.{rar,mkv,avi}")
  end
end


class MovieTorrent < Torrent
  def initialize(p, t)
    super(p,t)
    last_char = (@file_name =~ /\d{4}|#{RELEASE_TYPE}|#{MOVIE_EDITION}|#{MOVIE_SOURCE}/i) - 2
    @title = clean_title(@file_name[0..last_char])
    @dst_dir = "#{MOVIE_DIR}/#{@title}/"
    @files = Dir.glob("*.{rar,mkv,avi,nfo,srt,sub,jpg}")
  end
end
