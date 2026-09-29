# skyuv Windows 构建记录

## 日期

2026-09-29

## 环境

- 操作系统：Windows 10 x64
- 编译器：Visual Studio 2022 MSVC 19.41.34123.0
- CMake：已使用 skyuv 官方 Windows preset
- skyuv：Git 子模块 `3c8d9454b9644de8932c8159f554809441187217`
- skyuv 内置 Skynet：`2251550a785480fb04c343da1eb8b42f9a8484fd`
- libuv：`a6d06ba716b6facdf00e29306aa5013d51e070d4`

## 执行命令

```powershell
git submodule update --init --recursive
.\scripts\msvc.ps1 -Action all -Preset windows-msvc-debug -Jobs 4 -Fresh
```

## 结果

skyuv Windows Debug 运行时构建成功，并完成 63 项 CTest：

```text
100% tests passed out of 63
Total Test time (real) = 54.97 sec
```

已验证的范围包括：

- portable Skynet 最小节点和 TCP echo。
- client socket、stdin、gate、harbor、cluster。
- Lua C 模块、共享数据、netpack、memory 和 multicast。
- 动态模块、线程、时间、原子操作和 socket 压力测试。
- 安装运行时、归档内容、静态 CRT 和多项协议/Actor benchmark。

## 结论

Windows 不需要构建原版 Skynet 可执行文件即可获得可运行的 Skynet 兼容运行时。当前项目尚未完成
业务配置、`package` 服务和项目自有 C 模块接入；下一步是将这些目标编译到 skyuv 运行时目录并启动
本项目的 `server/config-pb`。

## 已知警告

- skyuv 部分头文件在中文系统代码页下出现 C4819 编码警告，但未阻断构建和测试。
- 本项目旧版 lsocket 尚未接入 Windows 构建；skyuv 自带的 client socket 模块已通过测试。
