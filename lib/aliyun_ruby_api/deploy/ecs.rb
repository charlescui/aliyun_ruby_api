module Aliyun
    module Deploy
        class Ecs
            class NoPublicIpExecption < RuntimeError;end
            
            def initialize(h={})
                @h = h
            end
            
            def is_running?
                @h["Status"].downcase == "running"
            end

            # "PublicIpAddress"=>{"IpAddress"=>["121.40.82.36"]},
            def public_ip_address
                if @h["PublicIpAddress"] and @h["PublicIpAddress"]["IpAddress"]
                    case ips = @h["PublicIpAddress"]["IpAddress"]
                    when Array
                        ip = @h["PublicIpAddress"]["IpAddress"].first
                        if ip != ''
                            return ip
                        else
                            return nil
                        end
                    when String
                        ip = @h["PublicIpAddress"]["IpAddress"]
                        if ip != ''
                            return ip
                        else
                            return nil
                        end
                    else
                        return nil
                    end
                end
                return nil
            end

            def check_web_service(port=8088)
                @prefix = "ECS #{@h["InstanceId"]} - #{@h["HostName"]}"
                if ip = public_ip_address
                    uri = URI.parse("http://#{ip}:#{port}")
                    puts "#{@prefix} #{uri}"
                    s = RestClient.get uri.to_s
                    # puts "#{@prefix} checking web server"
                    if (s.code.to_s =~ /2\d\d/) || (s.code.to_s =~ /3\d\d/)
                        # puts "#{@prefix} web service is alive"
                        return true
                    end
                else
                    raise NoPublicIpExecption, "#{@prefix} this ecs has no public ip"
                end
            end

            def is_web_serving?(port=8088)
                begin
                    return self.check_web_service(port)
                rescue Errno::ECONNREFUSED => e
                    return false
                rescue RestClient::BadGateway => e
                    return false
                end
            end
        end
    end
end