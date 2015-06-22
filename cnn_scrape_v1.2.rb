require 'rest-client'
require 'nokogiri'
require 'json'
require 'date'
require 'sendgrid-ruby'

start = Time.now
@today = "#{start.year}-0#{start.month}-#{start.day}"
@yesterday = "#{start.year}-0#{start.month}-#{start.day - 1}"

#candidates = ["Hillary Clinton","Jeb Bush","Ted Cruz","Lindsey Graham","Rick Perry","Marco Rubio"]#,"Bernie Sanders","Rand Paul","Rick Santorum"



#Get announced candidates from 2016election.com into an array 
candidates = []
candiUrls = ["http://www.2016election.com/list-of-declared-republican-presidential-candidates/","http://www.2016election.com/list-of-declared-democratic-presidential-candidates/"]
candiUrls.each {|url|
	@resp = RestClient.get(url, 'User-Agent' => 'Ruby')
	@page = Nokogiri::HTML(@resp)
	@candis = @page.xpath("//div[@class='vw-post-content clearfix']/p[3]").text.strip.split("\n")
	#more search query string manipulation than fox scraper v1
	@candis.each{|candi| candidates << candi}
}

=begin


candidates.each do |c|
	puts c.class
	puts c
	puts ""
end


=end

stories = []
candidates.each{|candi|
	@hsh = {}
    @hsh["candidate"] = candi
    @hsh["stories"] = []
   	 
   	 @url = "http://searchapp.cnn.com/search/query.jsp?page=1&npp=1000&start=1&text=#{candi.gsub("’","").gsub(" ","%2B").downcase}&type=all&sort=date&startDate=#{@yesterday}&collection=STORIES"
   	 @resp = RestClient.get(@url, 'User-Agent' => 'Ruby')
   	 @page = Nokogiri::HTML(@resp)
   	 @pagehsh = JSON.load(@page.xpath("//textarea").text.strip)
   	 @results = @pagehsh["results"][0]
   	 @results.each {|hsh|
                @arr = []
                @arr << hsh['url']
                @arr << hsh['title']#.join() #join turns the array from(values_at) into a string
                @arr << hsh['description']
                @arr << hsh['mediaDateUts']
                @hsh["stories"] << @arr
    }
    stories << @hsh
}

#sort finals array by number of stories per candidate
stories.sort_by!{|hsh| -hsh["stories"].count }

#build email body as html string
html = "<html>\n<style type='text/css'>\n div.story { font-size: xxx-small; }\n</style>\n<body>\n\n"
html += "<h2>Yesterday's cnn.com candidate mentions<br>\n
		#{@yesterday}:</h2>\n"

stories.each{|hsh| 
	html += "<p><h3>#{hsh["stories"].count} - #{hsh["candidate"]}</h3>\n<div class='story'>\n"
	hsh["stories"].each {|arr|
	html += "&#8712; <a href='#{arr[0]}'>#{arr[1]}</a> "
	}
	html += "</div></p>\n"
}
html += "<p><center>******<br>About this email:</center></p>
				<p>*The counts above are crude: they do not count candidate name mentions within articles, nor does the count methodology verify completeness of articles published on foxnews.com about a given candidate on a given day.<br> 
				*The counts above do reflect the number of daily aritcles returned by a foxnew.com search of a candidate's name.<br>
				*Candidates found: http://www.2016election.com/<br>
				*The script that generated this email took #{Time.now-start} seconds to run</p>"
html += "</body></html>"


#send email
client = SendGrid::Client.new(api_user: "nSmoth", api_key: "nick3141")

email = SendGrid::Mail.new do |m|
  m.to      = ['digitaldoesnthurt@gmail.com','david.a.lindsey@gmail.com']#
  m.from    = 'digitaldoesnthurt@gmail.com'
  m.subject = "CNN Candidate Mentions #{@yesterday}"
  m.html    = html #File.open("/Users/nSmith/Desktop/ELECTION_MASTER/Daily_HTML/#{@dateFor}.html").read
end

client.send(email)

puts "Script took #{Time.now-start} seconds to run"

