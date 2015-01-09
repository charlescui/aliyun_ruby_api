require 'rubygems'
require 'aliyun_ruby_api'

$DEBUG=true

parameters = {}

puts service.DescribeRegions parameters

options = {:access_key_id => "xxxxxxx",
           :access_key_secret => "yyyyyyyyyy",
           :endpoint_url => "https://ess.aliyuncs.com/"}

service = Aliyun::Service.new options
parameters = {
    :Version => "2014-08-28",
    :RegionId => "xxxxxxx"
}
pp service.DescribeScalingGroups parameters
