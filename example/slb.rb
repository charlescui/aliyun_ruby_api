require 'rubygems'
require 'aliyun_ruby_api'

$DEBUG=true

parameters = {}

puts service.DescribeRegions parameters

options = {:access_key_id => "lbxirhq7cO1Gc2dG",
           :access_key_secret => "terZhCBs8Wv8Gswx1pHevS7zwEN9N2",
           :endpoint_url => "https://slb.aliyuncs.com/"}

service = Aliyun::Service.new options
parameters = {
    :Version => "2014-05-15"
}
pp service.DescribeRegions parameters
