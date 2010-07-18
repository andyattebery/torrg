require 'rubygems'
require 'net/http'
require 'xmlsimple'

class Torrent

  def initialize(p, t)
    @path = p
    @torrent = t
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
  
  def escape_path(path)
    path = path.gsub(" ", "\\ ")
    path = path.gsub("'", "\\\\'")
    path = path.gsub("(", "\\(")
    path = path.gsub(")", "\\)")
    path = path.gsub("[", "\\[")
    path = path.gsub("]", "\\]")
  end
  
end

class MusicTorrent < Torrent
  def initialize
    get_info()
  end
    
  def organize
    dir = "#{MUSIC_DIR}/#{@artist[0]}/#{@artist}/#{@year} - #{@album}"
    if !File.exists?(dir) then Dir.mkdirs(dir) end
    if File.exists?("Folder.jpg") then File.rename("Folder.jpg", "folder.jpg") end
    if !File.exists?("folder.jpg") then get_albumart() end
  end
  
  private
  def move_flac
    files = Dir.glob("*.flac")
    files.each do |f|
      escaped_f = escape_path(f)
      `metaflac --show-tag=TITLE #{escaped_f}` =~ /TITLE=(.*)/
      title = $1
      `metaflac --show-tag=TRACKNUMBER #{escaped_f}` =~ /TRACKNUMBER=(.*)/
      number = $1
      FileUtils.mv(f, "#{number} - #{title}.flac")
    end
  end
  
  
  
  def get_info
    # @torrent =~ /^(.+)\ -\ (.+)\ -\ (\d{4})\ \((.+)\ -\ (.+)\ -\ (.+)\).torrent$/
    @torrent =~ /^(.+)\ -\ (.+)\ -\ (\d{4})/
    @artist = $1
    @album = $2
    @year = $3
  end
  
  def get_albumart
    url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&" +
          "api_key=#{API_KEY}&artist=#{@artist}&album=#{@album}"
    uri = URI.parse(URI.escape(url))
    response = Net::HTTP.get_response(uri).body
    xml = XmlSimple.xml_in(response)
    albumart_url = xml["album"][0]["image"][3]["content"]
    albumart_uri = URI.parse(albumart_url)
    open("folder.jpg", "wb") { |f| f.write(Net::HTTP.get_response(albumart_uri).body) }
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
