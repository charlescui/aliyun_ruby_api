require "aliyun_ruby_api/version"
require "aliyun_ruby_api/base"
require "aliyun_ruby_api/service"
if defined? Rails
    require "aliyun_ruby_api/rails/cdn"
end
require "aliyun_ruby_api/deploy/deploy"