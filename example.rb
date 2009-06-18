#!/usr/bin/ruby

require 'rubygems'
require 'lib/metar'
require 'lib/fetch'
require 'lib/groups'
require 'lib/taf'

## argument is ICAO-format station code
#raw = WX::Fetch.metar('KTEB')

#puts decode = WX::MetarReport.parse(raw)

raw = WX::Fetch.taf('KTEB')

taf =  WX::TafReport.parse(raw)
puts "Station: #{taf.station}"
puts "Time: #{taf.time}"
puts "TAF Time: #{taf.tafTime}"
puts "Is Amendment: #{taf.amendment}"
puts "Wind: #{taf.wind}"
puts "Visibility: #{taf.visibility}"
puts "RVR: #{taf.rvr}"

taf.weather.each do |wx|
  puts "Weather: #{wx.intensity} #{wx.descriptor} #{wx.phenomena}"
end

puts "Sky: #{taf.sky}"
puts "Partial Count: #{taf.partial.size.to_s}"
