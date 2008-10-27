#!/usr/bin/ruby

require 'rubygems'
require 'lib/metar'
require 'lib/fetch'
require 'lib/groups'

## argument is ICAO-format station code
raw = METAR::Fetch.station('KSAN')

puts decode = METAR::Report.parse(raw)

