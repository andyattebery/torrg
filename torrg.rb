#!/usr/bin/ruby

include torrent

# System constants
Root_storage_dir = "/mnt/gamma.beta/"
Root_dl_dir = "/home/andy/file.sharing/"

# Other constants
Movie_edition = "UNRATED|PROPER|LIMITED|Unrated"
Movie_source = "DVDRip|BDRip|R5|\d\d\d\d"
Movie_extras = "*.nfo *.srt *.jpg Subs"

Torrent.new(ARGV[0]).organize
