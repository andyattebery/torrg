class Helper
  
  def clean_name(name)
    name = name.gsub(/\b\w/) { $&.upcase }
    name = name.to_s
    name = name.gsub('.', '\ ')
    name = name.gsub('_', '\ ')
    name
  end

  def unrar(src, dst)
    rar_path = `find #{src} -type f -name '*.rar'`
    if(rar_path.to_s.match("part01"))
      rar_path =~ /(.+\.part01.rar)/
      rar_path = $1
    end
    rar_path = rar_path.chomp

    puts `mkdir -p #{dst}`
    puts "unrar e #{rar_path} #{dst}"
    puts `unrar e #{rar_path} #{dst}`
  end

end