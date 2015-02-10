module Aliyun
    module Deploy
        class EcsApi
            def initialize
                options = {:access_key_id => Aliyun::Deploy::Worker::ALIYUNACCESSKEYID,
                           :access_key_secret => Aliyun::Deploy::Worker::ALIYUNACCESSKEYSECRET,
                           :endpoint_url => "https://ecs.aliyuncs.com/"}

                @ecs_service = Aliyun::Service.new options
                @parameters = {
                    :Version => "2014-05-26"
                }
            end

            def reboot(id)
                parameters = @parameters.dup
                parameters[:InstanceId] = id
                @ecs_service.RebootInstance parameters
            end

            # 通过ECS的API获取RegionID
            # 杭州的：cn-hangzhou
            def regions
                @ecs_service.DescribeRegions @parameters
            end

            # 查询实例状态
            def query(id)
                parameters = @parameters.dup
                parameters[:InstanceId] = id
                h = @ecs_service.DescribeInstanceAttribute parameters
                Aliyun::Deploy::Ecs.new h
            end
        end
    end
end