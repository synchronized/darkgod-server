# 介绍
Forked from https://github.com/jintiao/some-mmorpg

## 运行
### 更新submodule
git submodule update --init --recursive
### 构建 skyuv 和项目模块
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug --target darkgod_package
### 编译proto文件
protoc --proto_path=proto/protobuf/source --descriptor_set_out=proto/protobuf/pb/protocol.pb proto/protobuf/source/*.proto
### 初始化redis数据库
tool/setup/setup.sh
tool/redis/start.sh
### 开始f服务器
tool/server/start.sh

# 前言

学习[skynet](https://github.com/cloudwu/skynet)时撸出来的简单服务器，欢迎吐槽。

完成度很低，已实现功能有：
* 登陆
* 角色创建
* 地图内移动
* 攻击
* aoi

# 编译及安装

## 编译依赖

### 3rd/openssl 
程序中用到了openssl中的crypto库，请将crypto编译成**静态库**。 [参考文档](https://wiki.openssl.org/index.php/Compilation_and_Installation)。  
对于64linux系统，可尝试用命令 "./Configure linux-x86_64 no-shared -fPIC; make"进行编译。   
如果编译出错，请自行google解决。

### 3rd/skyuv
[参考文档](https://github.com/synchronized/skyuv)。

## 安装
1. 先安装redis
2. 执行 `tool/setup/setup.sh`，它会在项目根目录下创建 `var` 目录和 Redis 配置。

## 运行
1. 运行 `tool/redis/start.sh`，启动对应的数据库实例。
2. 运行 `tool/server/start.sh`，启动 skyuv 服务器程序。

# 客户端

供测试用的客户端在 client 目录通过命令 “lua client.lua”或者脚本 “./run” 运行。

client.lua 接受用户名、密码作为命令行参数 “lua client.lua username password”，如果留空，则由程序自动生成一个用户名，保存在本地 anonymous 文件中。

client.lua 会自动完成登陆相关的流程，然后等待用户输入。

用户输入以回车结束，输入内容将打包发送至服务器。
输入的格式为 “命令 参数”，全部命令请参考 common/proto/game_proto.lua 文件中的 game_proto.c2s

一个常见的client命令流程是这样的：

```lua
cd client
./run
character_create character = { name = “hello”, race = “human”, class = “warrior” }
character_list
character_pick id = 4
map_ready
move pos = { x = 123, z = 321 }
combat target = 7
```

# 其他

详细说明请移步 [wiki](https://github.com/jintiao/some-mmorpg/wiki)
