# options = {
#     :access_key_id => $g_config[:aliyun][:access_key_id],
#     :access_key_secret => $g_config[:aliyun][:access_key_secret],
#     :domains => "http://cdn.example.com/"
# }

# $cdn = Aliyun::Rals::Cdn.new options

# # 记录缓存URL
# # 写在ApplicationController中的before_filter里面
# # app/controllers/application_controller.rb 
# after_filter ->{$cdn.record}

# # 清理缓存URL
# # 写在页面被运营人员变更的回调中
# # 清理具体的URI，包括该URI请求中包含各种各样的参数
# $cdn.clear_uri(path)
# # 清理某个Paht的父级目录
# $cdn.clear_dir(path)

module Aliyun
    module Rails
        class Cdn
            def initialize(options={})
                options = options.dup
                options[:endpoint_url] = "http://cdn.aliyuncs.com/" if !options[:endpoint_url]
                # 记录需要被CDN缓存的域名
                # 如果指定该参数，则当request请求是指向某个CDN域名的时候，才会被record方法记录
                # 该请求的URL才会被作为目标缓存清理
                @domains = [options.delete(:domains)].flatten if options[:domains]
                @service = Aliyun::Service.new options
            end
            
            ALIYUNCDNCACHEKEY = "ALIYUN::Rails::CDN"

            # 清理以path参数，作为URI的path值的URL
            # 该资源在阿里云CDN的具体URL，包括带参数的URL
            # 这些URL在请求CMS服务器的时候，被记录到memcache里面
            # path是如下格式：/cms/ce-shi
            def clear_uri(path)
                return if !Rails.cache

                key = self.cdn_key(path)
                urls = Rails.cache.read(key)
                if !urls.blank?
                    if urls.is_a? Array
                        begin
                            type = 'File'
                            # 清理CDN每个URL内容
                            urls.each { |e|  
                                rlt = @service.RefreshObjectCaches({
                                     ObjectPath: e,
                                     ObjectType: type
                                })
                                Rails.logger.info("aliyun cdn clear for #{e} and return #{rlt}")
                            }
                        rescue Exception => e
                            Rails.logger.error("aliyun cdn clear exception: #{e.inspect} #{e.message}")
                        end
                    else
                        Rails.logger.error("CDN: #{urls} is not an Array.")
                        Rails.cache.delete(key)
                    end
                end
            end

            # 清理该资源在阿里云CDN的目录
            # path是如下格式：/cms/ce-shi/wasu-test-entry
            def clear_dir(path)
                parent = get_parent_url(path)
                type = 'Directory'
                begin
                    rlt = @service.RefreshObjectCaches({
                         ObjectPath: parent,
                         ObjectType: type
                    })
                    Rails.logger.info("aliyun cdn clear for #{parent} and return #{rlt}")
                rescue Exception => e
                    Rails.logger.error("aliyun cdn clear exception: #{e.inspect} #{e.message}")
                end
            end

            # 记录客户端请求的URL,用于删除CDN缓存
            # 浏览器发起请求:
            # => "http://218.109.139.12:4343/hd/entry/exc?a=hello&b=2345678976"
            # 在ApplicationController中的过滤器中捕获
            # 保存如下数据结构:
            # => /hd/entry/exc => ["http://218.109.139.12:4343/hd/entry/exc?a=hello&b=2345678976"]
            def record
                return if !Rails.cache
                # 根据域名判断，如果这个CMS环境经过CDN缓存
                # 那么就记录这次请求的URL，带参数
                # 以便当页面更新时，告诉CDN服务器删除该URL
                if @domains
                    # 如果指定了CDN域名，则记录指定域名的请求
                    if @domains.is_a?(Array) and @domains.include?(request.host)
                        cache_record
                    end
                else
                    # 如果没有指定CDN域名，则记录全部
                    cache_record
                end
            end

            private

            def cdn_key(path)
                "#{ALIYUNCDNCACHEKEY}::#{path}"
            end

            def cache_record
                key = self.cdn_key(request.path)
                if (urls = Rails.cache.read(key)) and (urls.is_a? Array) and (urls.size > 0)
                    # 如果urls不为空，且没有保存过
                    if !urls.include?(request.url)
                        urls << request.url
                        Rails.cache.write(key, urls.uniq)
                    end
                else
                    # 如果urls为空
                    Rails.cache.write(key, [request.url])
                end
            end

            # 获取URL路径的上一级路径
            def get_parent_url(raw_url)
                url = URI.parse raw_url
                paths = url.path.split('/')
                paths.delete_if{|x|x.blank?}
                return if paths.size <= 0
                if paths.size == 1
                    parent = "http://#{$g_config[:aliyun][:domain]}/"
                else
                    paths.pop
                    parent = "http://#{$g_config[:aliyun][:domain]}/#{paths.join('/')}"
                end
            end
        end
    end
end