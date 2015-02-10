require 'net/http'
require 'time'
require 'securerandom'
require 'uri'
require 'base64'
require 'hmac-sha1'
require 'json'
require "pp"

module Aliyun
  
  class AliyunAPIException < RuntimeError
    attr_accessor :response
    
    def initialize(msg, response=nil)
      self.response = response if response
    end
  end
  
  class Service
    attr_accessor :options
    
    attr_accessor :access_key_id
    
    attr_accessor :access_key_secret
    
    attr_accessor :endpoint_url
    
    def initialize(options={})
      self.access_key_id = options[:access_key_id] || $ACCESS_KEY_ID || ""
      
      self.access_key_secret = options[:access_key_secret] || $ACCESS_KEY_SECRET || ""
      
      self.endpoint_url = options[:endpoint_url] || $ENDPOINT_URL || ALIYUN_API_ENDPOINT
      
      self.options = {:AccessKeyId => self.access_key_id}
    end
    
    #The method entry to call ECS url method
    def method_missing(method_name, *args)
      if $DEBUG
        puts "Not Found Method: #{method_name}"
      end
      
      if args[0].nil?
        args[0] = {}
      end
      
      call_aliyun_with_parameter(method_name, args[0])
    end

    #Dispatch the request with parameter
    private
    
    def call_aliyun_with_parameter(method_name, params={})
      params = gen_request_parameters method_name, params.dup
      uri = URI(endpoint_url)
      uri.query = URI.encode_www_form(params)
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if (uri.scheme == "https")
      
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
      if $DEBUG
        puts "request url: #{uri.request_uri}"
      end
      
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      case response
        when Net::HTTPSuccess
        return JSON.parse(response.body)
      else
        raise AliyunAPIException.new "response error code: #{response.code} and details #{response.body}", response
      end
    end
    
    #generate the parameters
    def gen_request_parameters method_name, params
      #add common parameters
      # 如果params中包含相同Hash，则以params为准
      # 避免诸如Version经常变化的参数写死在代码中
      params = DEFAULT_PARAMETERS.merge params
      params.merge! self.options
      
      params[:Action] = method_name.to_s
      params[:TimeStamp] = Time.now.utc.iso8601
      params[:SignatureNonce] = SecureRandom.uuid
      params[:Signature] = compute_signature params
      
      params
    end
    
    #compute the signature of the parameters String
    def compute_signature params
      if $DEBUG 
        puts "all params:"
        pp params
        puts $/
        puts "keys before sorted:"
        pp params.keys
      end
      
      sorted_keys = params.keys.sort
      
      if $DEBUG 
        puts "keys after sorted:"
        pp sorted_keys
      end
      
      canonicalized_query_string = ""
      
      sorted_keys.each {|key| canonicalized_query_string << SEPARATOR
        canonicalized_query_string << percent_encode(key.to_s)
        canonicalized_query_string << '='
        canonicalized_query_string << percent_encode(params[key])
      }
      
      length = canonicalized_query_string.length
      
      string_to_sign = HTTP_METHOD + SEPARATOR + percent_encode('/') + SEPARATOR + percent_encode(canonicalized_query_string[1,length])
      
      if $DEBUG 
        puts "string_to_sign is  #{string_to_sign}"
      end
      
      signature = calculate_signature access_key_secret+"&", string_to_sign
    end
    
    #calculate the signature
    def calculate_signature key, string_to_sign
      hmac = HMAC::SHA1.new(key)
      hmac.update(string_to_sign)
      signature = Base64.encode64(hmac.digest).gsub("\n", '')
      if $DEBUG 
        puts "signature #{signature}"
      end
      signature
    end
    
    #encode the value to aliyun's requirement
    def percent_encode value
      value = URI.encode_www_form_component(value).gsub(/\+/,'%20').gsub(/\*/,'%2A').gsub(/%7E/,'~')
    end
    
  end#class Service
end#Aliyun
