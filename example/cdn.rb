require 'rubygems'
require 'aliyun_ruby_api'

$DEBUG=true

options = {:access_key_id => "xxxxxx",
           :access_key_secret => "yyyyy",
           :endpoint_url => "https://cdn.aliyuncs.com/"}

service = Aliyun::Service.new options
parameters = {
    :Version=>"2014-11-11"
}
pp service.DescribeCdnService parameters
