# Aliyun API Client for Ruby


The Aliyun 开放平台 API Client for Ruby 是调用 [阿里云 ECS服务](http://aliyunecs.oss.aliyuncs.com/ECS-API-Reference%202014-05-26.pdf?spm=5176.7150518.1996836753.5.9U0YcN&file=ECS-API-Reference%202014-05-26.pdf) 和 [阿里云 CDN服务](http://imgs-storage.cdn.aliyuncs.com/help/oss/oss%20api%2020140828.pdf?spm=5176.7150518.1996836753.5.OT7PX3&file=oss%20api%2020140828.pdf) 的 [Ruby]客户端类库.

## 目前支持

- cdn
- ecs
- ess
- rds
- slb

## 安装

可以将下面一行加入Ruby应用的Gemfile:

    gem 'aliyun_ruby_api'

之后执行:

    $ bundle

或者直接执行:

    $ gem install aliyun_ruby_api

## 使用方法：

首先，需要在代码中引入类库:

```
require 'rubygems'
require 'aliyun_ruby_api'
```

然后利用自己阿里云账号下的access_key初始化service对象。如果没有access_key，可以通过[阿里云用户中心](https://i.aliyun.com/access_key/)申请access_key。

### ECS的API使用方法

```
options = {:access_key_id => "xxxxxx", 
           :access_key_secret => "yyyyyy", 
           :endpoint_url => "https://ecs.aliyuncs.com/"}

service = Aliyun::Service.new options
```

这样, 你就可以根据 [阿里云弹性计算服务API参考手册](http://help.aliyun.com/view/11108189_13730407.html)初始化业务参数（除Action参数之外）为一个hash对象，并且将其作为参数传给Action方法（Action参数）。

```
parameters = {
    :Version => "2014-05-26",
    :[parameter_name] => [parameter_value]
}

service.[Action] parameters
```

(1) 例如查询可用地域列表，其Action参数为DescribeRegions，而没有其他参数，代码如下

```
parameters = {
    :Version => "2014-05-26"
}

service.DescribeRegions parameters
```

(2) 再比如查询可用镜像，代码如下

```
parameters = {:RegionId => "cn-beijing", :PageNumber => 2, :RageSize => 20}

service.DescribeImages parameters
```

注意:

如果想要输出更详细的debug信息，请将下面这行加入到阿里云API调用

```
$DEBUG = true

```

### CDN的API使用方法

参考example目录的cdn.rb

## 基于阿里云的弹性伸缩组服务重启

将阿里云开放平台的Key和Secret，通过环境变量传进去:

`ALIYUNACCESSKEYID=kkkkkkkkkkkkkk ALIYUNACCESSKEYSECRET=ssssssssssssssssssssssssssssssssssss irb`

    # 重启弹性伸缩组的所有服务器
    require "aliyun_ruby_api"
    @deploy = Aliyun::Deploy::Worker.new(Aliyun::Deploy::EcsApi.new, Aliyun::Deploy::EssApi.new("bY8sLhdgqZB3cIu7Ufdj4dTZ"))
    @deploy.make

以上代码完成了如下任务:
- 找到ESS伸缩组及伸缩组中所有ECS服务
- 重启所有ECS服务
- 其中，手动接入ESS伸缩组的服务，在重启完毕后要再重新加入ESS
- 结束

## 基于阿里云CDN的内容更新处理

    options = {
        :access_key_id => $g_config[:aliyun][:access_key_id],
        :access_key_secret => $g_config[:aliyun][:access_key_secret],
        :domains => "http://cdn.example.com/"
    }

    $cdn = Aliyun::Rals::Cdn.new options

    # 记录缓存URL
    # 写在ApplicationController中的after_filter里面
    # app/controllers/application_controller.rb 
    after_filter ->{$cdn.record}

    # 清理缓存URL
    # 写在页面被运营人员变更的回调中
    # 清理具体的URI，包括该URI请求中包含各种各样的参数
    $cdn.clear_uri(path)
    # 清理某个Paht的父级目录
    $cdn.clear_dir(path)

### 关于Version参数

哎呦，这个参数很讨厌，经常变，要去ECS和CDN的API手册中查找，阿里云会在新版本的手册中给出Version的参数。如果ECS错误使用了CDN的Version，调用API是会失败的，反之亦然。

- [阿里云 ECS服务](http://aliyunecs.oss.aliyuncs.com/ECS-API-Reference%202014-05-26.pdf?spm=5176.7150518.1996836753.5.9U0YcN&file=ECS-API-Reference%202014-05-26.pdf)
- [阿里云 CDN服务](http://imgs-storage.cdn.aliyuncs.com/help/oss/oss%20api%2020140828.pdf?spm=5176.7150518.1996836753.5.OT7PX3&file=oss%20api%2020140828.pdf)

## 参考例子

可以参考example下面的文件来实现。
