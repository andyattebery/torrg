require 'fileutils'

class Action
  def initialize(files, dst_dir)
    @files = files
    @dst_dir = dst_dir
  end
  
  def execute()
    NotImplementedError
  end
  
  private
  def copy_to_dst(files, dst)
    if !File.exists?(dst)
      FileUtils.mkdir_p(dst)
      FileUtils.cp_r(files, dst)
      Dir.chdir(dst)
    else
      raise "Destination directory already exists"
    end
  end
  
  def rename_ext(file_pattern, ext, new_name)
    if (f = Dir.glob("#{file_pattern}.#{ext}")).any?
      File.rename(f[0], "#{new_name}.#{ext}")
    end
  end
  
  def escape_path(path)
    path = path.gsub(" ", "\\ ")
    path = path.gsub("'", "\\\\'")
    path = path.gsub("(", "\\(")
    path = path.gsub(")", "\\)")
    path = path.gsub("[", "\\[")
    path = path.gsub("]", "\\]")
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
end

class FlacAction
  def initialize(files, dst_dir)
    super(files, dst_dir)
  end
  
  def execute
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
    rename_ext("Folder", "jpg", "folder")
    if !File.exists?("folder.jpg") then get_albumart() end
    rename_ext("*", "m3u", "#{@artist} - #{@year} - #{@album}")
    rename_ext("*", "cue", "#{@artist} - #{@album}")
    rename_ext("*", "log", "#{@artist} - #{@album}")
  end
end

class PromoOnlyAction < Action
  def initialize(files, dst_dir)
    super(files, dst_dir)
  end
  
  def execute
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

class UnrarAction < Action
  def initialize(files, dst_dir)
    super(files, dst_dir)
    @rar_file = (f = Dir.glob("*.part01.rar")).any? ? f : Dir.glob("*.rar")
    @files.delete_if { |f| f =~ /\.r[a\d][r\d]$/ }
  end
  
  def execute
    if !File.exists?(@dst_dir) then FileUtils.mkdir_p(@dst_dir) end
    system("unrar e #{escape_path(@rar_file)} #{escape_path(@dst_dir)}")
    FileUtils.cp_r(@files, @dst_dir)
  end
end

class MoveAction < Action
  def initialize(files, dst_dir)
    super(files, dst_dir)
  end
  
  def execute
    if !File.exists?(@dst_dir) then FileUtils.mkdir_p(@dst_dir) end
    src_dir = Dir.pwd
    FileUtils.cp_r(@files, @dst_dir)
    FileUtils.rm_r(@files)
    Dir.chdir(@dst_dir)
    FileUtils.ln_s(@files, src_dir)
  end
end