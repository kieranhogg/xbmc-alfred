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

      unless settings.has_key? "host"
        puts "First setup the remote host IP or hostname using 'xbmc host'."
        next
      end

    args = query.split("=")
    movie = args.last

    request = '{"jsonrpc": "2.0", "params": {"item": {"movieid": ' + movie + '}}, "method": "Player.Open", "id": 1}'
    Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
  rescue Exception => e
    File.open("./log.txt", 'w') {|f| f.write(e.message) }
  end
end
