#!/usr/bin/ruby

include torrent

# System constants
ROOT_STORAGE_DIR = "/home/andy"
ROOT_DL_DIR = "/home/andy/file.sharing/"

MUSIC_DIR = "~/music"

# Other constants
MOVIE_EDITION = "UNRATED|PROPER|LIMITED|Ultimate\.Cut|Directors\.Cut"
MOVIE_SOURCE = "DVDRip|BDRip|R5|TS|TeleSync"
MOVIE_EXTRAS = "*.nfo, *.srt, *.jpg, Subs"

Torrent.new(ARGV[0]).organize
