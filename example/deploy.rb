require 'rubygems'
require 'aliyun_ruby_api'

$access_key_id = "lbxirhq7cO1Gc2dG"
$access_key_secret = "terZhCBs8Wv8Gswx1pHevS7zwEN9N2"

class EssApi
    def initialize
        options = {:access_key_id => $access_key_id,
                   :access_key_secret => $access_key_secret,
                   :endpoint_url => "https://ess.aliyuncs.com/"}

        @ess_service = Aliyun::Service.new options
    end

    def fetch_all_instances(page = 1, per = 1, &blk)
        # 查询伸缩组中所有ECS服务器
        parameters = {
            :Version => "2014-08-28",
            :RegionId => 'cn-hangzhou',
            :ScalingGroupId => "bY8sLhdgqZB3cIu7Ufdj4dTZ",
            :PageNumber => page,
            :PageSize => per
        }

        instance = @ess_service.DescribeScalingInstances parameters

        if blk and instance["ScalingInstances"] and instance["ScalingInstances"]["ScalingInstance"]
            if instance["ScalingInstances"]["ScalingInstance"].is_a? Array
                instance["ScalingInstances"]["ScalingInstance"].each { |e|
                    puts "Get One instance:"
                    puts e.inspect
                    blk.call e
                }
            end
        end

        if (instance["PageNumber"].to_i * instance["PageSize"].to_i) < instance["TotalCount"]
            page += 1
            fetch_all_instances(page, per, &blk)
        end
    end
end

class EcsApi
    def initialize
        options = {:access_key_id => $access_key_id,
                   :access_key_secret => $access_key_secret,
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
        @ecs_service.DescribeInstanceAttribute parameters
    end
end


ess = EssApi.new
ecs = EcsApi.new

# 每台服务器的实例
# {"CreationTime"=>"2015-02-02T06:07Z",
#  "CreationType"=>"AutoCreated",
#  "HealthStatus"=>"Healthy",
#  "InstanceId"=>"i-23bx98ksg",
#  "LifecycleState"=>"InService",
#  "ScalingConfigurationId"=>"cStN2jdJR3BGcweiuTeHXAiq",
#  "ScalingGroupId"=>"bY8sLhdgqZB3cIu7Ufdj4dTZ"}
ess.fetch_all_instances{|e|
    if id = e["InstanceId"]
        ecs.reboot(id)
        puts "ECS #{id} is rebooted."
        condition = true
        while condition
            if h = ecs.query(id)
                if h["Status"].downcase == "running"
                    puts "ECS #{id} is running."
                    condition = false
                else
                    sleep 5
                end
            else
                puts "Query #{id} is null!"
                sleep 5
            end
        end
    end
}