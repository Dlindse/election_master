require 'rest-client'
require 'nokogiri'
require 'json'
require 'date'
require 'sendgrid-ruby'

start = Time.now

@fstories = []

#Get announced candidates from 2016election.com into an array 
candidates = []
candiUrls = ["http://www.2016election.com/list-of-declared-republican-presidential-candidates/","http://www.2016election.com/list-of-declared-democratic-presidential-candidates/"]
candiUrls.each {|url|
	@resp = RestClient.get(url, 'User-Agent' => 'Ruby')
	@page = Nokogiri::HTML(@resp)
	@candis = @page.xpath("//div[@class='vw-post-content clearfix']/p[3]").text.strip.split("\n")
	@candis.each{|candi| candidates << candi.gsub("’","")}
}

#Pages we want scraped
@pages = [0,10,20,30]#,40,50,60
#Date we want count for
@today = Time.now
@dateFor = "#{@today.year}-0#{@today.month}-#{@today.day - 1}"
finals = []

candidates.each {|candidate|
	@hsh = {}
	@hsh["candidate"] = "#{candidate}"
	@hsh["stories"] = []
	
	@pages.each_with_index {|page, i|
		furl = "http://api.foxnews.com/v1/content/search?q=#{candidate}&fields=date,title,url,taxonomy&section.path=fnc&sort=latest&start=#{page}&callback=angular.callbacks._0"
		fresp = RestClient.get(furl, 'User-Agent' => 'Ruby')
		fpage = Nokogiri::HTML(fresp)

		foxresult = fpage.xpath("//body").text.strip
		foxnum = foxresult.rindex(/"docs":/) + 7
		cleanfoxresult = foxresult[foxnum...-3]
		@foxArr = JSON.load(cleanfoxresult)
		@foxArr.each {|hsh|
			 if DateTime.strptime(hsh["date"]).to_date.to_s == @dateFor
		 		@arr = []
		 		@arr << hsh["title"] 
		 		@arr << hsh["url"][0]
		 		@arr << DateTime.strptime(hsh["date"]).to_date
				@hsh["stories"] << @arr
			end
		}	
	}
finals << @hsh
}

#sort finals array by number of stories per candidate
finals.sort_by!{|hsh| -hsh["stories"].count }

#build email body as html string
html = "<html>\n<style type='text/css'>\n div.story { font-size: 6px; }\n</style>\n<body>\n\n"
html += "<h2>foxnews.com candidate mentions for<br>\n
		#{@dateFor}:</h2>\n"

finals.each{|hsh| 
	html += "<p><h3>#{hsh["stories"].count} - #{hsh["candidate"]}</h3>\n<div class='story'>\n"
	hsh["stories"].each {|arr|
	html += "&#8712; <a href='#{arr[1]}'>#{arr[0]}</a> "
	}
	html += "</div></p>\n"
}
html += "<p><center>******<br>About this email:</center></p>
				<p>*The counts above are crude: they do not count candidate name mentions within articles, nor does the count methodology verify completeness of articles published on foxnews.com about a given candidate on a given day.<br> 
				*The counts above do reflect the number of daily aritcles returned by a foxnew.com search of a candidate's name.<br>
				*Candidates found: http://www.2016election.com/ </p>"
html += "</body></html>"

#puts html
#puts "/Users/nSmith/Desktop/ELECTION_MASTER/Daily_HTML/#{@dateFor}.html"



#send email
client = SendGrid::Client.new(api_user: "nSmoth", api_key: "nick3141")

email = SendGrid::Mail.new do |m|
  m.to      = ['digitaldoesnthurt@gmail.com','david.a.lindsey@gmail.com']#
  m.from    = 'digitaldoesnthurt@gmail.com'
  m.subject = "Yesterday's Candidate Mentions (#{@dateFor})"
  m.html    = html #File.open("/Users/nSmith/Desktop/ELECTION_MASTER/Daily_HTML/#{@dateFor}.html").read
end

client.send(email)

=begin
=end
puts "Script took #{start - Time.now} seconds to run"