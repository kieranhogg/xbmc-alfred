#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require 'uri'
require 'net/http'

Alfred.with_friendly_error do |alfred|
  settings = alfred.setting.load
  base_url = "http://#{settings['host']}"

  begin
    query = ARGV.join(" ").strip
    args = query.split(" ")
    num_args = args.count
    if args.count == 1
      tv_show = args.last.split("=").last
      File.open("./tv_show.txt", 'w') {|f| f.write(tv_show) }
      File.open("./tv_season.txt", 'w') {|f| f.write("") }
    elsif args.count == 2
      season = args.last.split("=").last
      File.open("./tv_season.txt", 'w') {|f| f.write(season) }
    elsif args.count == 3
      episode = args.last.split("=").last
      File.open("./tv_show.txt", 'w') {|f| f.write("") }
      File.open("./tv_season.txt", 'w') {|f| f.write("") }

      request = '{"jsonrpc": "2.0", "params": {"item": {"episodeid": '+ episode + '}}, "method": "Player.Open", "id": 1}'
      Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
    end
  rescue Exception => e
    File.open("./error_log.txt", 'w') {|f| f.write(e.message) }
  end
end