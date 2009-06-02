require 'ruby-units'

# Extends ruby-unit's Unit class
class Unit
  attr_accessor :minus 
  attr_accessor :plus
  # Was this value reported as "less than"?
  def minus?
    @minus
  end
  # Was this value reported as "greater than"?
  def plus?
    @plus
  end
  alias :greater_than :plus
  alias :less_than :minus
  alias :greater_than? :plus?
  alias :less_than? :minus?
  alias :old_to_s :to_s #:nodoc:
  def to_s #:nodoc:
    s = old_to_s
    if minus?
      s = "<"+s
    elsif plus?
      s = ">"+s
    end
    s
  end
end

module WX
  # METAR codes are subdivided into "groups". The classes in this module do the
  # heavy lifting of parsing, and provide the API to access the relevant
  # information
  module Groups
    class Time < ::Time
      # raw date/time group, e.g. 252018Z
      # creates a ::Time object within the past month
      def self.parse(raw)
        raise ArgumentError unless raw =~ /^(\d\d)(\d\d)(\d\d)Z$/
        t = ::Time.now.utc
        y = t.year
        m = t.month
        mday = $1.to_i
        hour = $2.to_i
        min  = $3.to_i
        
        if t.mday < mday
          m -= 1
        end
        if m < 1
          m = 12
          y -= 1
        end
        return ::Time.utc(y,m,mday,hour,min)
      end
    end
    
    class TAFTime < ::Time
      #convert 3012/3112 to time objects
      
      def self.parse(raw)
        raise ArgumentError unless raw =~ /^(\d\d)(\d\d)\/(\d\d)(\d\d)$/
        
        timeArray = Array.new
        
        t = ::Time.now.utc
        
        y = t.year
        m = t.month
        
        timeStartMonthDay = $1.to_i
        timeStartHour = $2.to_i
        timeStartMin = 0
        
        if t.mday < timeStartMonthDay
          m -= 1
        end
        if m < 1
          m = 12
          y -= 1
        end
        
        if(timeStartHour == 24)
          timeStartHour = 23
          timeStartMin = 59
        end
        
        timeArray.push(::Time.utc(y, m, timeStartMonthDay, timeStartHour, timeStartMin))
        
        timeEndMonthDay = $3.to_i
        timeEndHour = $4.to_i
        timeEndMin = 0
        
        if(timeEndHour == 24)
          timeEndHour = 23
          timeEndMin = 59
        end
        
        timeArray.push(::Time.utc(y, m, timeEndMonthDay, timeEndHour, timeEndMin))
        
        return timeArray
      end
    end

    class Wind
      # Angle Unit
      attr_reader :direction
      alias :dir :direction
      alias :deg :direction
      def radians
        @direction.to 'rad'
      end
      def degrees
        @direction.to 'deg'
      end
      alias :rads :radians
      alias :rad :radians
      # Speed Unit
      attr_reader :speed
      def mph
        @speed.to 'mph'
      end
      def knots
        @speed.to 'knots'
      end
      alias :kts :knots
      # Speed Unit
      attr_reader :gust
      alias :gusts :gust
      alias :gusting_to :gust
      def gusting?
        @gust
      end
      alias :gusts? :gusting?
      alias :gust? :gusting?
      # If wind is strong and variable, this will be a two-element Array
      # containing the angle Unit limits of the range, e.g.  ['10 deg'.unit,
      # '200 deg'.unit]
      attr_reader :variable 
      alias :variable_range :variable
      def initialize(raw)
        raise ArgumentError unless raw =~/(\d\d\d|VRB)(\d\d\d?)(G(\d\d\d?))?(KT|KMH|MPS)( (\d\d\d)V(\d\d\d))?/

        case $5 
        when 'KT'
          unit = 'knots'
        when 'KMH'
          unit = 'kph'
        when 'MPS'
          unit = 'm/s'
        end
        @speed = "#{$2} #{unit}".unit
        if $1 == 'VRB'
          @direction = 'VRB'
        else
          @direction = "#{$1} degrees".unit
        end

        @gust = "#{$4} knots".unit if $3

        if $6
          @variable = ["#{$7} deg".unit, "#{$8} deg".unit]
        end
      end
      # If wind is strong and variable or light and variable
      def variable?
        @variable or vrb?
      end
      def vrb?
        @direction == 'VRB'
      end
      def calm?
        @speed == '0 knots'.unit
      end
      # returns one of the eight compass rose names
      # e.g. N, NNE, NE, ENE, etc.
      def compass
        a = degrees.abs
        i = (a/22.5).round % 16
        %w{N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW}[i]
      end
      def to_s
        return "calm" if calm?
        # print a float to d decimal places leaving off trailing 0s
        def pf(f,d=2)
          s = sprintf("%.#{d}f",f)
          s.gsub!(/(\.0+|(\.\d*[1-9])0+)$/, '\2')
          s
        end

        if vrb?
          s = "Variable"
        elsif variable?
          v1, v2 = variable
          s = "From #{pf v1.to('deg').abs} to #{pf v2.to('deg').abs} degrees"
        else
          s = "#{degrees.abs} degrees (#{compass})"
        end

        s += " at #{pf speed.to('knots').abs} knots "
        s += "(#{pf speed.to('mph').abs,1} MPH; #{pf speed.to('m/s').abs,1} m/s)"
        if gusting?
          s += "\n" + (" "*22)
          s += "gusting to #{pf gust.to('knots').abs,1} knots "
          s += "(#{pf gust.to('mph').abs,1} MPH; #{pf gust.to('m/s').abs,1} m/s)"
        end
        s
      end
    end

    # How many statute miles of horizontal visibility. May be reported as less
    # than so many miles, in which case Unit#minus? returns true.
    class Visibility < Unit
      attr_reader :plus, :d
      
      def initialize(raw)        
        if(raw =~ /^P(\d)SM$/)
          @d = $1
          @plus = true
          super("#{d} mi")
        elsif(raw =~ /^(M?)(\d+ )?(\d+)(\/(\d+))?SM$/)
          @minus = true if $1 == 'M'
          if $4
            @d = $3.to_f / $5.to_f
          else
            @d = $3.to_f
          end
          if $2
            @d += $2.to_f
          end
          super("#{d} mi")
        else
          raise ArgumentError
        end
      end
      
      def to_s
        if @plus == true
          "Greater than #{d} miles"
        else
          "#{d} mi"
        end
      end
      
    end

    # How far down a runway the lights can be seen
    class RunwayVisualRange
      # Which runway
      attr_reader :runway
      alias :rwy :runway
      # How far. If variable, this is a two-element Array giving the limits.
      # Otherwise it's a Unit.
      attr_reader :range
      alias :distance :range
      alias :dist :range
      def initialize(raw)
        raise ArgumentError unless raw =~ /^R(\d+[LCR]?)\/([PM]?)(\d+)(V([P]?)(\d+))?FT$/
        @runway = $1
        @range = ($3+' feet').unit
        @range.minus = true if $2 == 'M'
        @range.plus = true if $2 == 'P'
        if $4
          r1 = @range
          r2 = "#{$6} feet".unit
          r2.plus = true if $5 == 'P'
          @range = [r1,r2]
        end
      end
      # Is the visibility range variable?
      def variable?
        Array === @range
      end
      def to_s
        if variable?
          "On runway #{rwy}, from #{dist[0]} to #{dist[1]}"
        else
          "On runway #{rwy}, #{dist}"
        end
      end
    end
    # Weather phenomena in the area. At the moment this is a very thin layer
    # over the present weather group of METAR. Please see
    # FMH-1 Chapter
    # 12[http://www.nws.noaa.gov/oso/oso1/oso12/fmh1/fmh1ch12.htm#ch12link]
    # section 6.8 for more details.
    class PresentWeather
      # One of [:light, :moderate, :heavy]
      attr_reader :intensity
      # The descriptor. e.g. 'SH' means showers
      attr_reader :descriptor
      # The phenomena. An array of two-character codes, e.g. 'FC' for funnel
      # cloud or 'RA' for rain.
      attr_reader :phenomena
      def phenomenon
        @phenomena.first
      end
      def initialize(raw)
        r = /^([-+]|VC)?(MI|PR|BC|DR|BL|SH|TS|FZ)?((DZ|RA|SN|SG|IC|PE|PL|GR|GS|UP)*|(BR|FG|FU|VA|DU|SA|HZ|PY)*|(PO|SQ|FC|SS|DS)*)$/
        raise ArgumentError unless raw =~ r

        case $1
        when '-'
          @intensity = :light
        when nil
          @intensity = :moderate
        when '+'
          @intensity = :heavy
        when 'VC'
          @intensity = :vicinity
        end

        @descriptor = $2

        @phenomena = []
        s = $3
        until s.empty?
          @phenomena.push(s.slice!(0..1))
        end
      end
      # Alias for intensity
      def proximity
        @intensity
      end
    end
    # Information about clouds or lack thereof
    class Sky
      # Cloud cover. A two-character code. (See FMH-1
      # 12.6.9[http://www.nws.noaa.gov/oso/oso1/oso12/fmh1/fmh1ch12.htm#ch12link])
      attr_reader :cover
      alias :clouds :cover
      # Distance Unit to the base of the cover type. 
      attr_reader :height
      alias :base :height
      def initialize(raw)
        raise ArgumentError unless raw =~ /^(SKC|CLR)|(VV|FEW|SCT|BKN|OVC)(\d\d\d|\/\/\/)(CB|TCU)?$/

        if $1
          @clr = ($1 == 'CLR')
          @skc = ($1 == 'SKC')
        else
          @cover = $2
          @cb = ($4 == 'CB')
          @tcu = ($4 == 'TCU')
          @height = "#{$1}00 feet".unit if $3 =~ /(\d\d\d)/
        end
      end
      # Is the sky clear?
      def skc?
        @skc
      end
      alias :clear? :skc?
      # Is the sky reported clear by automated equipment (meaning it's clear up
      # to 12,000 feet at least)?
      def clr?
        @clr
      end
      alias :auto_clear? :clr?
      # Are there cumulonimbus clouds? Only when reported by humans.
      def cb?
        @cb
      end
      alias :cumulonimbus? :cb?
      # Are there towering cumulus clouds? Only when reported by humans.
      def tcu?
        @tcu
      end
      alias :towering_cumulus? :tcu?
      # Is this a vertical visibility restriction (meaning they can't tell
      # what's up there above this height)
      def vv?
        @cover == 'VV'
      end
      alias :vertical_visibility? :vv?
      def to_s
        if skc? 
          s = "Clear"
        elsif clr?
          s = "Clear below 12000 ft"
        elsif vv?
          s = "Vertical visibility #{height}"
        else
          s = Contractions[@cover] + " at #{height}"
        end
      end
      Contractions = {'FEW'=>'Few', 'SCT'=>'Scattered', 'BKN' => 'Broken', 'OVC' => 'Overcast'}
    end
  end
end
