require 'rest-client'
require 'nokogiri'
require 'json'
require 'date'


start = Time.now


#Get announced candidates from 2016election.com into an array
candidates = []
candiUrls = ["http://www.2016election.com/list-of-declared-republican-presidential-candidates/","http://www.2016election.com/list-of-declared-democratic-presidential-candidates/"]
candiUrls.each {|url|
    @resp = RestClient.get(url, 'User-Agent' => 'Ruby')
    @page = Nokogiri::HTML(@resp)
    @candis = @page.xpath("//div[@class='vw-post-content clearfix']/p[3]").text.strip.split("\n")
    @candis.each{|candi| candidates << candi.gsub("’","")}
}

puts candidates

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++