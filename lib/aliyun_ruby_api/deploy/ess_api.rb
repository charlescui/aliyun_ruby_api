module Aliyun
    module Deploy
        # http://imgs-storage.cdn.aliyuncs.com/help/ess/弹性伸缩服务API手册.pdf?spm=5176.775974890.2.4.1LJfkS&file=弹性伸缩服务API手册.pdf
        class EssApi
            # 入参是伸缩组的ID
            def initialize(scaling_group_id)
                options = {:access_key_id => Aliyun::Deploy::Worker::ALIYUNACCESSKEYID,
                           :access_key_secret => Aliyun::Deploy::Worker::ALIYUNACCESSKEYSECRET,
                           :endpoint_url => "https://ess.aliyuncs.com/"}

                @ess_service = Aliyun::Service.new options
                @scaling_group_id = scaling_group_id
            end

            def fetch_all_instances(page = 1, per = 10, &blk)
                # 查询伸缩组中所有ECS服务器
                parameters = {
                    :Version => "2014-08-28",
                    :RegionId => 'cn-hangzhou',
                    :ScalingGroupId => @scaling_group_id,
                    :PageNumber => page,
                    :PageSize => per
                }

                instance = @ess_service.DescribeScalingInstances parameters

                # {"CreationTime"=>"2015-02-09T10:34Z", "CreationType"=>"Attached", "HealthStatus"=>"Healthy", "InstanceId"=>"i-2399b44hs", "LifecycleState"=>"InService", "ScalingConfigurationId"=>"", "ScalingGroupId"=>"bY8sLhdgqZB3cIu7Ufdj4dTZ"}
                if blk and instance["ScalingInstances"] and instance["ScalingInstances"]["ScalingInstance"]
                    if instance["ScalingInstances"]["ScalingInstance"].is_a? Array
                        instance["ScalingInstances"]["ScalingInstance"].each { |e|
                            puts "Get One instance:"
                            puts e.inspect
                            blk.call e["InstanceId"], e["CreationType"]
                        }
                    end
                end

                if (instance["PageNumber"].to_i * instance["PageSize"].to_i) < instance["TotalCount"]
                    page += 1
                    fetch_all_instances(page, per, &blk)
                end
            end

            def attach_instances(ids=[])
                # 添加某些服务器到伸缩组
                parameters = {
                    :Version => "2014-08-28",
                    :RegionId => 'cn-hangzhou',
                    :ScalingGroupId => @scaling_group_id
                }
                ids.each_with_index { |e, idx| parameters["InstanceId.#{idx+1}".to_sym] = e }
                begin
                    instance = @ess_service.AttachInstances parameters
                    puts instance
                rescue AliyunAPIException => e
                    if e.response
                        instance = JSON.parse(e.response.body)
                        # 已经加入伸缩组的机器，再次加入伸缩组会报错，这部分错误可以忽略
                        if !(instance["Code"] == "InvalidInstanceId.InUse")
                            puts "#{e.message} - #{instance} - #{parameters}"
                        end
                    end
                end
            end
        end
    end
end