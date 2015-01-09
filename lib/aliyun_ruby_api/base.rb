module Aliyun
    ALIYUN_API_ENDPOINT='https://ecs.aliyuncs.com/'
    
    SEPARATOR = "&"
    
    HTTP_METHOD = "GET"
    
    DEFAULT_PARAMETERS = {
        :Format=>"JSON",
        :Version=>"2014-11-11", 
        :SignatureMethod=>"HMAC-SHA1", 
        :SignatureVersion=>"1.0"
    }
end