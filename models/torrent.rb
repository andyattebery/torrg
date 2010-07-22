require 'net/http'
require 'FileUtils'
require 'rubygems'
require 'xmlsimple'
require 'mp3info'
require 'id3lib'

class Torrent

  def initialize(file_path, torrent_path)
    torrent_path =~ /\/([^\/]+)\/([^\/]+)\/([^\/]+)$/
    @tracker = $1
    @type = $2
    @torrent = $3
    
    file_path =~ /^(.*)\/([^\/]+)$/
    @name = $2
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
          "api_key=#{LASTFM_API_KEY}&artist=#{@artist}&album=#{@album}"
    uri = URI.parse(URI.escape(url))
    response = Net::HTTP.get_response(uri).body
    xml = XmlSimple.xml_in(response)
    albumart_url = xml["album"][0]["image"][3]["content"]
    albumart_uri = URI.parse(albumart_url)
    open("folder.jpg", "wb") { |f| f.write(Net::HTTP.get_response(albumart_uri).body) }
  end
end


class MusicFlacTorrent < Torrent
  def initialize(f, t)
    super(f,t)
    @torrent =~ /^(.+)\ -\ (.+)\ -\ (\d{4})/
    @artist = $1
    @album = $2
    @year = $3
    @dst = "#{MUSIC_DIR}/Artists/#{@artist[0..0]}/#{@artist}/#{@year} - #{@album}"
    @files = Dir.glob("*.{flac,jpg,m3u,cue,log,nfo}")
  end
  
  def organize
    copy_to_dst(@files, @dst)
    # Rename music files based on tags
    Dir.glob("*.flac").each do |f|
      escaped_f = escape_path(f)
      `metaflac --show-tag=TITLE #{escaped_f}` =~ /TITLE=(.*)/
      title = $1
      `metaflac --show-tag=TRACKNUMBER #{escaped_f}` =~ /TRACKNUMBER=(.*)/
      number = $1
      if title != nil && number != nil
        File.rename(f, "#{number} - #{title}.flac")
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
    @dst = "#{MUSIC_DIR}/Collections/Mainstream Radio/#{@year} - Mainstream Radio/" +
            "#{MONTH_NUMS[@month]} - Mainstream Radio [#{@month.capitalize} #{@year}]"
    @files = Dir.glob("*.{mp3,m3u,nfo,jpg}")
  end
   
  def organize
    copy_to_dst(@files, @dst)
    # Organize extras
    if (c = Dir.glob("*[fF]ront*.jpg")) then FileUtils.cp(c[0], "folder.jpg") end
    rename_ext("*[fF]ront*", "jpg", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year} - Front")
    rename_ext("*[bB]ack*", "jpg", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year} - Back")
    rename_ext("*", "nfo", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year}")
    rename_ext("*", "m3u", "Promo Only Mainstream Radio - #{@month.capitalize} #{@year}")
    puts "Got here"
    # Rename music files based on tags
    Dir.glob("*.mp3").each do |f|
      puts f
      tag = ID3Lib::Tag.new(f)
      if ( (num = tag.track) != nil) && 
            ((title = tag.title) != nil) &&
            ((artist = tag.artist) != nil )
        num =~ /(\d+)\//
        num = 1 == $1.length ? "0#{$1}" : $1
        tag.album = "Promo Only Mainstream Radio " +
                    "[#{MONTH_NUMS[@month]} - #{@month.capitalize} #{@year}]"
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
        tag.update!
        File.rename(f, "#{num} - #{artist} - #{title}.mp3")
      end
    end
  end
end

class MovieTorrent < Torrent
  def initialize(p, t)
    super(p,t)
    @dir_name =~ /^([\w\.]*)\.(\d{4}\.)?(#{MOVIE_EDITION}|#{MOVIE_SOURCE})*/i
    @artist = $1
    @album = $2
    @year = $3
    @dst = "#{MUSIC_DIR}/#{@artist[0..0]}/#{@artist}/#{@year} - #{@album}"
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


class TVShowTorrent < Torrent
  def self.new(path)
    puts "New TV Show torrent: #{path}"
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
