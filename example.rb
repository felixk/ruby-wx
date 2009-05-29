#!/usr/bin/ruby

require 'rubygems'
require 'lib/metar'
require 'lib/fetch'
require 'lib/groups'

## argument is ICAO-format station code
raw = WX::Fetch.taf('KTEB')

#puts decode = WX::MetarReport.parse(raw)

puts raw
