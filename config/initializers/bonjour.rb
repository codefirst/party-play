hostname = `hostname`.chop.split(".").first
DNSSD.register hostname, '_partyplay._tcp', nil, (ENV['PORT'] || '3000').to_i do |r|
  puts "registered #{r.fullname}"
end

