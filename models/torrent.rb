require 'net/http'
require 'FileUtils'
require 'rubygems'
require 'xmlsimple'
require 'id3lib'

class Torrent

  def initialize(p, t)
    @path = p
    @torrent = t
    @path =~ /^#{DOWNLOAD_DIR}\/([\w\.]*)\/[\w\.]*\/([\w\.]*)\//
    @tracker = $1
    @dir_name = $2
    Dir.chdir(@path)
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
  
  def rename_ext(ext, filename)
    if (f = Dir.glob("*.#{ext}")).any?
      File.rename(f[0], "#{filename}.#{ext}")
    end
  end
  
end


class MusicTorrent < Torrent
  def initialize(p, t)
    super(p,t)
  end
    
  def organize
    if (files = Dir.glob("*.{flac,m3u,cue,log,jpg}")).any?      
      if !File.exists?(@dst) then FileUtils.mkdir_p(@dst) end
      FileUtils.cp_r(files, @dst)
      Dir.chdir(@dst)
      
      if Dir.glob("*.flac").any? then organize_flac end
      if (Dir.glob("*.mp3").any? && @path =~ /mainstream.radio/i) then organize_promo_only end 
    end
    
    Dir.glob("*").each do |f| 
      if File.directory?(f) then MusicTorrent.new(f, @torrent).organize() end
    end
  end
  
  private
  def organize_promo_only
    # Determin info
    @torrent.to_lower() =~ /(january|february|march|april|may|june|july|august|september|october|november|december)/
    @month = $1
    @torrent =~ /(\d{4})/
    @year = $1
    @dst = "#{MUSIC_DIR}/Collections/Mainstream Radio/#{@year} - Mainstream Radio/" +
            "#{MONTH_NUMS[@month]} - Mainstream Radio [#{@month.capitalize} #{@year}]"
    # Rename music files based on tags
    Dir.glob("*.mp3").each do |f|
      Mp3Info.open(f) do |mp3|
        if ( (num = mp3.tag.tracknum) != nil) && 
              ((title = mp3.tag.title) != nil) &&
              ((artist = mp3.tag.artist) != nil )
          File.rename(f, "#{num} - #{artist} - #{title}.mp3")
        end
      end
    end
    # Organize extras
    rename_ext("nfo", "Promo Only Mainstream Radio - #{@month.capitalize} #{year}")
    rename_ext("m3u", "Promo Only Mainstream Radio - #{@month.capitalize} #{year}")
  end
  
  def organize_flac(dir)
    # Determine info
    @torrent =~ /^\/#{TORRENT_DIR}\/.+\/.+\/(.+)\ -\ (.+)\ -\ (\d{4})/
    @artist = $1
    @album = $2
    @year = $3
    @dst = "#{MUSIC_DIR}/Artists/#{@artist[0..0]}/#{@artist}/#{@year} - #{@album}"
    # Rename music files based on tags
    dir.each do |f|
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
    rename_ext("m3u", "#{@artist} - #{@year} - #{@album}")
    rename_ext("cue", "#{@artist} - #{@album}")
    rename_ext("log", "#{@artist} - #{@album}")
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
