#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"

require 'json'
require 'uri'
require 'net/http'
require 'open-uri'

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback
  settings = alfred.setting.load
  query = ARGV.join(" ").strip
  value = query.partition('=').last

  if query.start_with? 'set_host'
    alfred.setting.dump({ "host", value })
    puts "Host has been changed to '#{value}'."
    next
  end

  unless settings.has_key? "host"
    puts "First setup the remote host IP or hostname using 'xbmc host'."
    next
  end

  base_url = "http://#{settings['host']}"

  case value
  when "stop" # Now Playing
    request = '{"jsonrpc":"2.0","id":1,"method":"Player.Stop", "params": { "playerid": 1 }, "id": 1}'
    Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
  when "playpause" # Play/Pause
    request = '{"jsonrpc":"2.0","id":1,"method":"Player.PlayPause", "params": { "playerid": 1 }, "id": 1}'
    Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
  when "update"
    request = '{"jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}'
    Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
  else
    puts "Unknown command '#{value}'."
  end
end
