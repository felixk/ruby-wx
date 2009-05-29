require 'net/http'
require 'uri'

module WX

class Fetch

  def self.metar(station_id)
    server = 'weather.noaa.gov'
    port = '80'
    path = '/cgi-bin/mgetmetar.pl?cccc=' +station_id

    begin
      http = Net::HTTP.new(server, port)
      http.read_timeout = 300
      res = http.get(path)
    rescue SocketError => e
      puts "Could not connect!"
      exit
    end

    case res
      when Net::HTTPSuccess
        data = res.body
        data.split(/\n/).each do |line|
          if  line =~ /^#{station_id}/  
            report = line
            return report
          end
      end
    end
  end
  
  def self.taf(station_id)
    server = 'weather.noaa.gov'
    port = '80'
    path = '/cgi-bin/mgettaf.pl?cccc=' + station_id

    begin
      http = Net::HTTP.new(server, port)
      http.read_timeout = 300
      res = http.get(path)
    rescue SocketError => e
      puts "Could not connect!"
      exit
    end
  
    case res
      when Net::HTTPSuccess
        data = res.body.gsub(/\n/, ' ').gsub(/ +/, ' ')
        if  data =~ /<pre>(.*?)<\/pre>/  
          report = $1
          return report
        end
    end
    
  end
  
end
  
end
