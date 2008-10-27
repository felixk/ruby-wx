## ruby-metar

This is a fork of Hans Fugal's possibly-not-maintained 'ruby-wx' library
which parses METAR data into human readable output.
 
For clarity, the "WX" module has been renamed to "METAR" and the former "METAR" class becomes "Report".

I have introduced a "Fetch" class which handles the automatic retrieval of reports from a NOAA source.

Current work will focus on a TAF parser and refactoring.
