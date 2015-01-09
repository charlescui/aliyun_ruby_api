require 'rubygems'
require 'aliyun_ruby_api'

$DEBUG=true

options = {:access_key_id => "xxxxxx",
           :access_key_secret => "yyyyy",
           :endpoint_url => "https://ecs.aliyuncs.com/"}

service = Aliyun::Service.new options
parameters = {
    :Version => "2014-05-26"
}
pp service.DescribeRegions parameters
