#!/usr/bin/ruby

require 'yaml'
require File.expand_path('../models/torrent_factory', __FILE__)
require File.expand_path('../models/torrent', __FILE__)

# Configuration
CONF = YAML.load_file('torrg.yml')
MOVIE_DIR = File.expand_path(CONF['movie dir'])
MUSIC_DIR = File.expand_path(CONF['music dir'])
TVSHOW_DIR = File.expand_path(CONF['tv show dir'])

LASTFM_API_KEY = "0ac34ed861402be0abe6201163bf3243"

# Constants
MOVIE_EDITION = "UNRATED|PROPER|LIMITED|Ultimate\.Cut|Directors\.Cut"
MOVIE_SOURCE = "DVDRip|BDRip|R5|TS|TeleSync"
MOVIE_EXTRAS = "*.nfo, *.srt, *.jpg, Subs"
MONTH_NUMS = Hash["january" => "01",
              "february" => "02",
              "march" => "03",
              "april" => "04",
              "may" => "05",
              "june" => "06",
              "july" => "07",
              "august" => "08",
              "september" => "09",
              "october" => "10",
              "november" => "11",
              "december" => "12"]

# Execute
TorrentFactory.instance().create_torrent(ARGV[0], ARGV[1]).organize()