#!/usr/bin/ruby

require 'rubygems'
require 'lib/metar'
require 'lib/fetch'
require 'lib/groups'
require 'lib/taf'

## argument is ICAO-format station code
raw = WX::Fetch.metar('KTEB')

puts decode = WX::MetarReport.parse(raw)

raw = WX::Fetch.taf('KTEB')

puts WX::TafReport.parse(raw).sky
