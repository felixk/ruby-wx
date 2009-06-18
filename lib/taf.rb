require 'rubygems' rescue nil
require 'lib/exceptions'
require 'lib/groups'
require 'ruby-units'
require 'stringio'

module WX
  class TafReport
    include Groups
    
    attr_accessor :raw
    attr_accessor :station
    attr_accessor :time
    attr_accessor :tafTime
    attr_accessor :amendment
    attr_accessor :wind
    attr_accessor :visibility
    attr_accessor :rvr
    attr_accessor :weather
    attr_accessor :sky
    attr_accessor :partial
    
    def self.parse(raw)
      m = TafReport.new
      m.raw = raw
      groups = raw.split
      
      g = groups.shift
      
      if g != "TAF"
        raise ParseError, "Can't parse TAF: #{g} "
        return nil
      end
      
      g = groups.shift
      
      if g =~ /AMD/
        amendment = true
        g = groups.shift
      end  
      
      if g =~ /^([a-zA-Z0-9]{4})$/
        m.station = $1
        g = groups.shift
      else
        raise ParseError, "Invalid Station Identifier '#{g}'"
      end
      
      if g =~ /^(\d\d)(\d\d)(\d\d)Z$/
        m.time = Time.parse(g)
        g = groups.shift
      else
        raise ParseError, "Invalid Date and Time '#{g}'"
      end
      
      if g =~ /^(\d\d)(\d\d)\/(\d\d)(\d\d)$/
        m.tafTime = TAFTime.parse(g)
        g = groups.shift
      else
        raise ParseError, "Invalid Date and Time '#{g}'"
      end
    
      # wind
      if g =~ /^((\d\d\d)|VRB)(\d\d\d?)(G(\d\d\d?))?(KT|KMH|MPS)$/
        if groups.first =~ /^(\d\d\d)V(\d\d\d)$/
          g = g + ' ' + groups.shift
        end
        m.wind = Wind.new(g)
        g = groups.shift
      end
      
      # visibility
      if g =~ /^\d+$/ and groups.first =~ /^M?\d+\/\d+SM$/
        m.visibility = Visibility.new(g+' '+groups.shift)
        g = groups.shift
      elsif g =~ /^M?\d+(\/\d+)?SM$/
        m.visibility = Visibility.new(g)
        g = groups.shift
      elsif g =~ /^P\dSM$/
        m.visibility = Visibility.new(g)
        g = groups.shift
      end

      # RVR
      m.rvr = []
      while g =~ /^R(\d+[LCR]?)\/([PM]?)(\d+)(V([PM]?)(\d+))?FT$/
        m.rvr.push RunwayVisualRange.new(g)
        g = groups.shift
      end

      # present weather
      m.weather = []
      while g =~ /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ|DZ|RA|SN|SG|IC|PE|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS)+$/
        m.weather.push PresentWeather.new(g)
        g = groups.shift
      end
      
      # sky condition
      m.sky = []
      while g =~ /^(SKC|CLR)|(VV|FEW|SCT|BKN|OVC)/
        m.sky.push Sky.new(g)
        g = groups.shift
      end

      m.partial = []

      begin
        if g =~ /^FM\d\d\d\d\d\d$/
          fromGroupRaw = g
              
          begin
            g = groups.shift
            if(g =~ /^FM\d\d\d\d\d\d$/ || g =~ /^TEMPO$/)
              groups.unshift(g)
              break
            elsif(g == nil)
              break
            else
              fromGroupRaw = fromGroupRaw + " " + g
            end
          end while true
          
          m.partial.push(WX::TAFReportPartial.parse(fromGroupRaw))
        elsif g =~ /^TEMPO$/
          tempoGroupRaw = g
        
          begin
            g = groups.shift
          
            if(g =~ /^FM\d\d\d\d\d\d$/ || g =~ /^TEMPO$/)
              groups.unshift(g)
              break
            elsif(g == nil)
              break
            else
              tempoGroupRaw = tempoGroupRaw + " " + g
            end
          end while true
          m.partial.push(WX::TAFReportPartial.parse(tempoGroupRaw))
        elsif g == nil
          break
        end
        
        g = groups.shift
      end while true
      
      return m
    end
  end
  
  class TAFReportPartial
        include Groups
    attr_accessor :raw
    attr_accessor :fromOrTempo
    attr_accessor :wind
    attr_accessor :visibility
    attr_accessor :rvr
    attr_accessor :weather
    attr_accessor :sky
    attr_accessor :time
    attr_accessor :prob

    def self.parse(raw)
      m = TAFReportPartial.new
      m.raw = raw
      groups = raw.split
      
      g = groups.shift

      if g =~ /^FM(\d\d\d\d\d\d)$/
        fromOrTempo = "FROM"
        m.time = Time.parse($1)
      elsif(g =~ /^TEMPO$/)
        fromOrTempo = "TEMPO"
        g = groups.shift
        if g =~ /^(\d\d)(\d\d)\/(\d\d)(\d\d)$/
          m.time = []
          m.time = TAFTime.parse(g)
          g = groups.shift
        else
          raise ParseError, "Invalid Date and Time '#{g}'"
        end
      elsif(g =~ /^PROB(\d\d)$/)
        prob = $1
        fromOrTempo = "PROB"
        g = groups.shift
        if g =~ /^(\d\d)(\d\d)\/(\d\d)(\d\d)$/
          m.time = []
          m.time = TAFTime.parse(g)
          g = groups.shift
        else
          raise ParseError, "Invalid Date and Time '#{g}'"
        end
      end
      
      # wind
      if g =~ /^((\d\d\d)|VRB)(\d\d\d?)(G(\d\d\d?))?(KT|KMH|MPS)$/
        if groups.first =~ /^(\d\d\d)V(\d\d\d)$/
          g = g + ' ' + groups.shift
        end
        m.wind = Wind.new(g)
        g = groups.shift
      end
      
      # visibility
      if g =~ /^\d+$/ and groups.first =~ /^M?\d+\/\d+SM$/
        m.visibility = Visibility.new(g+' '+groups.shift)
        g = groups.shift
      elsif g =~ /^M?\d+(\/\d+)?SM$/
        m.visibility = Visibility.new(g)
        g = groups.shift
      elsif g =~ /^P\dSM$/
        m.visibility = Visibility.new(g)
        g = groups.shift
      end

      # RVR
      m.rvr = []
      while g =~ /^R(\d+[LCR]?)\/([PM]?)(\d+)(V([PM]?)(\d+))?FT$/
        m.rvr.push RunwayVisualRange.new(g)
        g = groups.shift
      end

      # present weather
      m.weather = []
      while g =~ /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ|DZ|RA|SN|SG|IC|PE|PL|GR|GS|UP|BR|FG|FU|VA|DU|SA|HZ|PY|PO|SQ|FC|SS|DS)+$/
        m.weather.push PresentWeather.new(g)
        g = groups.shift
      end
      
      # sky condition
      m.sky = []
      while g =~ /^(SKC|CLR)|(VV|FEW|SCT|BKN|OVC)/
        m.sky.push Sky.new(g)
        g = groups.shift
      end

      return m
    end
  end
end
