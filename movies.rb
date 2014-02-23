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
  args = query.split(" ")
  num_args = args.count
  base_url = "http://#{settings['host']}"
  if !settings.has_key? 'host' or query.start_with? 'host'
    show_host_item(fb, query)
  else
    begin
      request = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetMovies", "id": "1"}'
      o = Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
      r = JSON.parse(o.body)

      r["result"]["movies"].each do |movie|
        title = movie["label"]
        id = movie["movieid"]

        fb.add_item({
          :uid      => "#{id}",
          :title    => "#{title}",
          :subtitle => "Play movie",
          :arg      => "show_movie=#{id}",
          :valid    => "yes",
        })

      end
    rescue Exception => e
      File.open("./error_log.txt", 'a') {|f| f.write(e.message) }
    end
  end
  puts fb.to_xml
end

