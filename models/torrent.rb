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
    raise NotImplementedError
  end
  
  private
  def clean_title(title)
    title = title.gsub(/\b\w/) { $&.upcase }
    title = title.gsub('.', '\ ')
    title = title.gsub('_', '\ ')
    title
  end
  
  def escape_path(path)
    path = path.gsub(" ", "\\ ")
    path = path.gsub("'", "\\\\'")
    path = path.gsub("(", "\\(")
    path = path.gsub(")", "\\)")
    path = path.gsub("[", "\\[")
    path = path.gsub("]", "\\]")
  end
  
  def rename_ext(file_pattern, ext, new_name)
    if (f = Dir.glob("#{file_pattern}.#{ext}")).any?
      File.rename(f[0], "#{new_name}.#{ext}")
    end
  end
  
  def copy_to_dst(files, dst)
    if !File.exists?(dst)
      FileUtils.mkdir_p(dst)
      FileUtils.cp_r(files, dst)
      Dir.chdir(dst)
    else
      raise "Destination directory already exists"
    end
  end
  
  def get_albumart
    url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&" +
          "api_key=0ac34ed861402be0abe6201163bf3243&artist=#{@artist}&album=#{@album}"
    uri = URI.parse(URI.escape(url))
    response = Net::HTTP.get_response(uri).body
    xml = XmlSimple.xml_in(response)
    albumart_url = xml["album"][0]["image"][3]["content"]
    albumart_uri = URI.parse(albumart_url)
    open("folder.jpg", "wb") { |f| f.write(Net::HTTP.get_response(albumart_uri).body) }
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
  
  def organize
    copy_to_dst(@files, @dst_dir)
    # Rename music files based on tags
    Dir.glob("*.flac").each do |f|
      escaped_f = escape_path(f)
      `metaflac --show-tag=TITLE #{escaped_f}` =~ /TITLE=(.*)/
      title = $1
      `metaflac --show-tag=TRACKNUMBER #{escaped_f}` =~ /TRACKNUMBER=(.*)/
      num = $1
      if title != nil && num != nil
        num = fix_track_num(num)
        File.rename(f, "#{num} - #{title}.flac")
      end
    end
    # Organize extras
    if File.exists?("Folder.jpg") then File.rename("Folder.jpg", "folder.jpg") end
    if !File.exists?("folder.jpg") then get_albumart() end
    rename_ext("*", "m3u", "#{@artist} - #{@year} - #{@album}")
    rename_ext("*", "cue", "#{@artist} - #{@album}")
    rename_ext("*", "log", "#{@artist} - #{@album}")
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
            "#{MONTH_NUMS[@month]} - Mainstream Radio [#{@month.capitalize} #{@year}]"
    @files = Dir.glob("*.{mp3,m3u,nfo,jpg}")
  end
   
  def organize
    copy_to_dst(@files, @dst_dir)
    # Organize extras
    if (c = Dir.glob("*[fF]ront*.jpg")) then FileUtils.cp(c[0], "folder.jpg") end
    rename_ext("*[fF]ront*", "jpg", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year} - Front")
    rename_ext("*[bB]ack*", "jpg", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year} - Back")
    rename_ext("*", "nfo", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year}")
    rename_ext("*", "m3u", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year}")
    # Rename music files based on tags
    Dir.glob("*.mp3").each do |f|
      tag = ID3Lib::Tag.new(f)
      if ( (num = tag.track) != nil) && 
            ((title = tag.title) != nil) &&
            ((artist = tag.artist) != nil )
        num =~ /(\d+)\//
        num = fix_track_num($1)
        tag.album = "Promo Only Mainstream Radio " +
                    "[#{MONTH_NUMS[@month]} - #{@month.capitalize} #{@year}]"
        # embed_artwork(tag)
        tag.update!
        File.rename(f, "#{num} - #{artist} - #{title}.mp3")
      end
    end
  end
  
  private 
  def embed_artwork(tag)
    if File.exists?("folder.jpg")
      cover = {
        :id           => :APIC,
        :mimetype     => 'image/jpeg',
        :picturetype  => 3,
        :description  => 'Front album art',
        :textenc      => 0,
        :data         => File.read("folder.jpg")
      }
      tag << cover
    end
  end
end


class TVShowTorrent < Torrent
  def initialize(file_path, torrent_path)
    super(file_path, torrent_path)
    @file_name =~ /^(.+)\.[Ss]{0,1}(\d+)x{0,1}[Ee]{0,1}\d+\./
    @title = clean_title($1)
    @season_num = $2
    @season_num = "0" == @season_num[0..0] ? @season_num[1..1] : @season_num
    @dst_dir = "#{TV_SHOW_DIR}/#{@title}/Season #{@season_num}"
    @files = Dir.glob("*.{rar,mkv,avi,nfo,srt,sub}")
  end
    
  def organize
    ActionFactory.instance.create_action(@files, @dst_dir).execute
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
    
  def organize
    ActionFactory.instance.create_action(@files, @dst_dir).execute
  end
  
  private
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
end
