require 'net/http'
require 'uri'
require 'json'

username = 'user@example.com'
password = 'mypassword'

url = 'https://guestlistapp.com/api/v0.1/events/'
#url = 'https://guestlistapp.com/api/v0.1/events/?page=2'
#url = 'https://guestlistapp.com/api/v0.1/events/12345/orders'
#url = "https://guestlistapp.com/api/v0.1/events/12345/orders/54321"

def query(url)
uri = URI(url)

req = Net::HTTP::Get.new(url)
req.basic_auth username, password

res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
  http.request(req)
}

JSON.parse(res.body)
end

# get events
results = []
results << query(url)

#puts results.first["total_pages"].inspect

if results.first["total_pages"] > 1 then
  results.first["total_pages"].times {|i|
    results << query(url+"?page="+(i+1).to_s)
  }
end

#puts results.inspect

events = []
results.each do |r|
  events += r["events"]
end

#puts events.inspect

puts "We have had #{events.count} events."
puts "The last one is #{events.last.inspect}."


event_detail_results = []

events.last(10).each do |e|
  event_detail_results << query(e)
end

event_detail_results.last(10).each do |e|
  published = "live"
  if e["published_at"].nil? then
    published = "NOT live"
  end

  puts "(#{e["start"]}) #{e["name"]} is #{published} and has #{e["orders"].count} out of #{e["max_tickets"]} sold."

  e["orders"].each do |o|
    order_result = query(o)

    if !order_result["first_name"].nil? && !order_result["last_name"].nil? then
      puts "  ORDER: "+order_result["first_name"]+" "+order_result["last_name"]
    else
      puts "  ORDER: nil"
    end
    order_result["tickets"].each do |t|
      ticket_result = query(t)
      if !ticket_result["first_name"].nil? && !ticket_result["last_name"].nil? then
        puts "    TICKET: "+ticket_result["first_name"]+" "+ticket_result["last_name"]
      else
        puts "    TICKET: nil"
      end
    end

  end

end

