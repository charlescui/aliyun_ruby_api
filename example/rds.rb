require 'rubygems'
require 'aliyun_ruby_api'

$DEBUG=true

parameters = {}

puts service.DescribeRegions parameters

options = {:access_key_id => "xxxxxxxxxx",
           :access_key_secret => "yyyyyyyyyyyyyyyyy",
           :endpoint_url => "https://rds.aliyuncs.com/"}

service = Aliyun::Service.new options
parameters = {
    :Version => "2014-08-15"
}
pp service.DescribeRegions parameters