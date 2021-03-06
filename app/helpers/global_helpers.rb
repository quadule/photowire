module Merb
  module GlobalHelpers
    DAY = /mon(day)?|tue|tues(day)?|wed(nesday)?|thu|thur(sday)?|fri(day)?|sat(urday)?|sun(day)?/i
    MONTH = /jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|june?|july?|aug(ust)?|sep|sept(ember)?|oct(ober)?|nov(ember)?|dec(ember)?/i
    DATE = Regexp.new "(#{DAY.source}\\.?)?\\s*(#{MONTH.source})\\.?\\s*(\\d{1,2})\\s*(\\d{4})", 'i'
    
    def find_date(str)
      Date.parse str[DATE, 0]
    rescue
      nil
    end
    
    def link_dates(str)
      str.gsub(DATE) do |match|
        date = Date.parse(match).strftime('%Y-%m-%d')
        replacement = tag :a, match, :href => url(:photos, :date => date)
      end
    end
    
    def add_links(str)
      str = link_dates str
    end
  end
end
