## ruby-metar

This is a fork of Hans Fugal's possibly-not-maintained 'ruby-wx' library
which parses METAR data into human readable output.
 
For clarity, the "WX" module has been renamed to "METAR" and the former "METAR" class becomes "Report".

I have introduced a "Fetch" class which handles the automatic retrieval of reports from a NOAA source.

Example:
 
$ ./example.rb 
KSAN 251851Z 31007KT 10SM BKN025 16/09 A3019 RMK AO2 SLP222 T01560094 
Conditions at:        KSAN
Temperature/Dewpoint: 16°C / 9°C (60.8°F / 48.2°F) [RH 62.8%]
Pressure (altimeter): 30.19 inches Hg (1022.4 mb)
Winds:                310.0 degrees (NW) at 7 knots (8.1 MPH; 3.6 m/s)
Visibility:           10 mi
Clouds:               Broken at 2500 ft
Remarks:              AO2 SLP222 T01560094
