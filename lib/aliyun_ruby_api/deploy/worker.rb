=begin
ALIYUNACCESSKEYID=kkkkkkkkkkkkkk ALIYUNACCESSKEYSECRET=ssssssssssssssssssssssssssssssssssss irb
# 重启弹性伸缩组的所有服务器
require "aliyun_ruby_api"
@deploy = Aliyun::Deploy::Worker.new(Aliyun::Deploy::EcsApi.new, Aliyun::Deploy::EssApi.new("伸缩组ID"))
@deploy.make
=end

module Aliyun
    module Deploy
        # 部署策略
        class Worker
            ALIYUNACCESSKEYID = ($aliyun_access_key_id || ENV['ALIYUNACCESSKEYID'])
            ALIYUNACCESSKEYSECRET = ($aliyun_access_key_secret || ENV['ALIYUNACCESSKEYSECRET'])

            # statics 指也要重新部署的非ESS服务器
            def initialize(ecs, ess, statics=[])
                @ecs = ecs
                @ess = ess
                @statics = statics
                @ecs_reboot_proc = proc{|id|
                    if id
                        @ecs.reboot(id)
                        puts "ECS #{id} is rebooting."
                        # 检查服务器启动状态
                        self.check_server_running_status(id)
                        # 检测Web服务是否启动
                        self.check_service_running_status(id)
                    end
                }
                @instances = []
                @attached = []
            end

            # 检查服务器的启动状态
            def check_server_running_status(id)
                condition = true
                # 检测服务器是否启动
                while condition
                    e = @ecs.query(id)
                    print '.'
                    if e and (e.is_running? )
                        puts ''
                        puts "ECS #{id} is rebooted."
                        condition = false
                        # 加入到ESS组
                        self.attach_to_scale(id)
                    else
                        sleep 5
                    end
                end
            end

            # 检测Web服务是否启动
            def check_service_running_status(id)
                e = @ecs.query(id)
                condition = true
                while condition
                    print '.'
                    begin
                        if e.is_web_serving?
                            puts ''
                            puts "ECS #{id} is served."
                            condition = false
                        else
                            sleep 5
                        end
                    rescue Ecs::NoPublicIpExecption => e
                        puts e.message
                        condition = false
                    end
                end
            end

            def attach_to_scale(id)
                # 如果是手动添加到ESS的服务器
                # 重启之后会被移除ESS，需要手动添加
                if @attached.include?(id)
                    @ess.attach_instances([id])
                end
            end
            
            def fetch_all_instances
                # 获取该弹性伸缩组下面所有服务器的ID
                @ess.fetch_all_instances{|id, type|
                    @instances << id
                    # 如果ESS集群中该服务器的类型是Attached，那么它是手工创建的服务器，重启后要再主动添加到ESS中
                    if type == "Attached"
                        @attached << id
                    end
                }
                @statics.uniq!
                # 组成全部服务器的ID
                @instances |= @statics
                @instances.uniq!
            end

            def make
                self.fetch_all_instances
                puts "@@@@@@@@@@Deploy Start@@@@@@@@@@"
                puts "@@@@@@@@@@#{Time.now.to_s}@@@@@@"
                begin
                    while id = @instances.pop
                        @ecs_reboot_proc.call(id)
                    end
                rescue Exception => e
                    puts "Left ECS(#{@instances.inspect.size}) :\n #{@instances.inspect}"
                    raise e
                end
                puts "@@@@@@@@@@#{Time.now.to_s}@@@@@@"
                puts "@@@@@@@@@@Deploy End@@@@@@@@@@"
            end
        end
    end
end