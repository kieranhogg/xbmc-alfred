#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require 'open-uri'
require 'json'
require 'uri'
require 'net/http'

def faux_query(query)
  query.length > 0 ? query : "..."
end

def show_host_item(fb, query)
  if query.start_with? 'host'
    query = query.partition('host').last.strip
  end
  fb.add_item({
    :uid      => "",
    :title    => "Set the Hostname",
    :subtitle => "Change the hostname or IP address to '#{faux_query(query)}'",
    :arg      => "set_host=#{query}",
    :valid    => "yes",
  })
end

Alfred.with_friendly_error do |alfred|
  fb = alfred.feedback
  settings = alfred.setting.load
  query = ARGV.join(" ").strip

 if !settings.has_key? 'host' or query.start_with? 'host'
       show_host_item(fb, query)
  else
    begin
    base_url = "http://#{settings['host']}"
    request = '{"jsonrpc": "2.0", "method": "Player.GetActivePlayers", "id": 1}'
    r = Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
    json_object = JSON.parse(r.body)

		if json_object["result"].empty?
			np = 'not playing'
		else 
		  np = 'playing'
			player_id = json_object["result"][0]["playerid"]
      request = '{"jsonrpc": "2.0", "method": "Player.GetItem", "params": { "properties": ["title", "season", "episode", "showtitle"], "playerid": 1 }, "id": "VideoGetItem"}'
      r = Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
      json_object = JSON.parse(r.body)
			episode_name = json_object["result"]["item"]["label"]
			title = json_object["result"]["item"]["showtitle"]
			series = json_object["result"]["item"]["season"]
			episode_no = json_object["result"]["item"]["episode"]
			playing = series.to_s + "x" + episode_no.to_s + " " + title + " - " + episode_name
		end

      if np.eql? 'playing'
        fb.add_item({
          :uid      => "",
          :title    => "Now playing #{playing}",
          :subtitle => "",
          :valid    => "no",
        })
        fb.add_item({
          :uid      => "",
          :title    => "Play/pause XBMC",
          :arg      => "run_command=playpause",
          :valid    => "yes",
        })
        fb.add_item({
          :uid      => "",
          :title    => "Stop XBMC",
          :subtitle => "",
          :arg      => "run_command=stop",
          :valid    => "yes",
        })
      else
          fb.add_item({
          :uid      => "",
          :title    => "XBMC not playing",
          :subtitle => "",
          :arg      => "",
          :valid    => "yes",
        })
      end
        fb.add_item({
          :uid      => "",
          :title    => "Update XBMC library",
          :subtitle => "",
          :arg      => "run_command=update",
          :valid    => "yes",
        })
    rescue Exception => e
      #show_host_item(fb, query)
	   File.open("./error_log.txt", 'w') {|f| f.write(url) }

    end
  end

  puts fb.to_xml
end

