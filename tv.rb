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
    if num_args == 2 #if we have a show and a series, show episodes
      season_num = query.split(" ").last
      show_num = query.split(" ").first

      request = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetEpisodes", "params": {"properties": 
        ["playcount", "plot", "season", "episode", "showtitle", "thumbnail", "fanart", "file", 
          "lastplayed", "rating"], "sort": {"method": "episode"}, "tvshowid":'+show_num+', 
          "season":'+season_num+'}, "id": 1}'

      o = Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
      r = JSON.parse(o.body)
         r["result"]["episodes"].each do |episode|
          title = episode["label"]
          id = episode["episodeid"]
          # TODO - doesn't seem to like resumetimeinseconds
          #if episode["resumetimeinseconds"] > 0
            #title = title + ' ' + '\u25BA'.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
          if episode["playcount"] > 0
            title = title + ' ' + '\u2713'.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
          end
             fb.add_item({
              :uid      => "",
              :title    => "#{title}",
              :subtitle => "Play episode",
              :arg      => "show_no=#{show_num} season_no=#{season_num} episode=#{id}",
              :valid    => "yes",
            })
     end
    elsif num_args == 1 # if we have a show, show seasons
      request = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetSeasons", "params": { "tvshowid" : ' + query + '} , "id": 1}'
      o = Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
      r = JSON.parse(o.body)

      r["result"]["seasons"].each do |series|
        season = series["label"]
        season_no = season.sub! 'Season ', ''

        fb.add_item({
          :uid      => "",
          :title    => "Season #{season}",
          :subtitle => "View episodes",
          :arg      => "show_no=#{args} season_no=#{season_no}",
          :valid    => "yes",
       })
      end
    else # show list of shows
      begin

        request = '{"jsonrpc": "2.0", "method": "VideoLibrary.GetTVShows", "params": {  
                "properties": ["title"], "sort": { "order": "ascending", "method": "title" } }, "id": "libTvShows"}'
        o = Net::HTTP.get_response(URI.parse(URI::encode("#{base_url}/jsonrpc?request=#{request}")))
        r = JSON.parse(o.body)

        r["result"]["tvshows"].each do |tv|
          title = tv["title"]
          id = tv["tvshowid"]
          fb.add_item({
            :uid      => "#{id}",
            :title    => "#{title}",
            :subtitle => "View show",
            :arg      => "show_show=#{id}",
            :valid    => "yes",
          })
        end
      rescue Exception => e
        File.open("./error_log.txt", 'w') {|f| f.write(e.message) }
      end
    end
  end
  puts fb.to_xml
end

