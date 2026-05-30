# shell

当前仓库是一个小型 Shell 脚本集合，主要包含回程路由测试、`tcping` 一键安装、`fzf` 安装更新，以及 DNS 配置辅助脚本。以下命令均以当前仓库根目录为准。

## 网络工具安装

### `install_tcping.sh`
一键安装 [tcping](https://github.com/pouriyajamshidi/tcping)。脚本会自动识别 Debian/Ubuntu 系统架构，并从官方 latest release 下载对应 `.deb` 包安装。

当前支持：

- `amd64`：下载 `tcping-amd64.deb`
- `arm64`：下载 `tcping-arm64.deb`

本地运行：

```bash
bash install_tcping.sh
```

远程运行：

```bash
curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/install_tcping.sh | bash
```

安装后可验证：

```bash
tcping -v
tcping www.example.com 443 -c 3
```

## 回程路由测试

### `autoBestTrace.sh`
主入口。自动检查 Root、按需安装 `nexttrace`，默认测试北京电信/联通/移动，也支持手动输入自定义 IP。

本地运行：

```bash
sudo bash autoBestTrace.sh
```

远程运行：

```bash
curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/autoBestTrace.sh | sudo bash
```

### `besttrace-new.sh`
当前内容与 `autoBestTrace.sh` 基本一致，可作为备用入口。

本地运行：

```bash
sudo bash besttrace-new.sh
```

远程运行：

```bash
curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/besttrace-new.sh | sudo bash
```

### `autoBestTrace-old.sh`
旧版回程测试脚本，使用仓库内的 `besttrace2021` 二进制；若文件不存在，脚本会自动下载。

```bash
bash autoBestTrace-old.sh
```

```bash
curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/autoBestTrace-old.sh | bash
```

如需直接调用旧版二进制，可手动执行：

```bash
./besttrace2021 -q 1 219.141.147.210
```

## 其他脚本

### `install_or_update_fzf.sh`
安装或更新 `fzf` 到 `~/.fzf`，并写入 `~/.bashrc`。

本地运行：

```bash
bash install_or_update_fzf.sh
```

远程运行：

```bash
curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/install_or_update_fzf.sh | bash
```

### `setup_dns.sh`
重置 `systemd-resolved` 相关配置，修改 `/etc/resolv.conf` 与 `/etc/systemd/resolved.conf`，需要 Root。当前脚本写入的是 `DNSOverTLS=no`。

本地运行：

```bash
sudo bash setup_dns.sh
```

远程运行：

```bash
curl -fsSL https://raw.githubusercontent.com/lcyan/shell/master/setup_dns.sh | sudo bash
```

## 说明

- `install_tcping.sh` 适用于 Debian/Ubuntu 的 `amd64` 和 `arm64`；其他架构请改用官方 tar.gz 或源码编译。
- `besttrace2021` 是旧版脚本依赖的二进制文件，不建议随意替换。
- `setup_dns.sh`、`autoBestTrace.sh`、`besttrace-new.sh` 都会修改系统状态或依赖网络，建议在可回滚环境中测试。
