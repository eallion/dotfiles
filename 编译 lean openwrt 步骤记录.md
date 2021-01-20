# 编译 lean openwrt 步骤记录

### 准备编译环境：

```
sudo apt-get update
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3.5 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget swig rsync
```
### Fork 源码，然后克隆：

```
cd ~
git clone https://github.com/coolsnowwolf/lede.git
```

### 修改 Feed 源：

```
vim feeds.conf.default
```

添加：

```
src-git helloworld https://github.com/fw876/helloworld
src-git lienol https://github.com/Lienol/openwrt-package
```

### 修改默认 IP：

```
sed -i 's/192.168.1.1/192.168.0.2/g' package/base-files/files/bin/config_generate
```

### 克隆 Aliddns ：

```
git clone https://github.com/chenhw2/luci-app-aliddns.git package/lean/luci-app-aliddns
```
### 克隆 Serverchan 微信推送：

```
git clone https://github.com/tty228/luci-app-serverchan.git package/lean/luci-app-serverchan
```

### 克隆  JD dailybonus 京东签到：

```
git clone https://github.com/jerrykuku/node-request.git package/lean/node-request #git node-request 依赖
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus.git package/lean/luci-app-jd-dailybonus
```

### 克隆 Openclash：

```
git clone --single-branch --branch master https://github.com/vernesong/OpenClash.git
cd OpenClash
mv luci-app-openclash ../package/lean/luci-app-openclash
```
### Update & Install Feeds ：

```
./scripts/feeds update -a && ./scripts/feeds install -a
```
### 配置选项：

```
make menuconfig
```
##### LuCI - Applications :

- luci-app-xxx

##### Network - SSH:

- openssh-sftp-server

##### Network - IP Addresses and Names:

- drill

### 预下载：

```
make -j8 download V=s
```
### 开始编译：

```
make -j1 V=s
```
如果是真机编译环境，-j 后面的参数可以设为实际CPU核心数的2倍。虚拟机还是老老实实用 -j1 。

### 摘取新源码：

```
git pull
```
### 编译新固件：

```
./scripts/feeds update -a && ./scripts/feeds install -a
```
```
make clean
make menuconfig
make -j8 download V=s
make -j1 V=s
```
### 二次编译：

```
cd lede
git pull
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig
make -j8 download
make -j$(($(nproc) + 1)) V=s
```

### 重新配置：

```
rm -rf ./tmp && rm -rf .config
make clean
make menuconfig
make -j$(($(nproc) + 1)) V=s
```

### 其他 make 参数：

```
make --help #查看 make 选项
make download # 仅下载make需要的文件
make defconfig # 默认配置
make package/xxxxxxxxx/compile # 构筑单个包
make clean  # 清除`/bin`和`/build_dir`文件夹
make dirclean  # 清除编译完成的文件和相对应工具链，相对应全面清除
make distclean  # 相对上面会清除配置和feeds
```
##### Openwrt 项目地址：

- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Lienol/openwrt](https://github.com/Lienol/openwrt)
- [openwrt/openwrt](https://github.com/openwrt/openwrt)

##### 添加一些其他的APP：

- [shadowsocks/openwrt-shadowsocks](https://github.com/shadowsocks/openwrt-shadowsocks)
- [honwen/openwrt-v2ray-plugin](https://github.com/honwen/openwrt-v2ray-plugin)
- [honwen/luci-app-aliddns](https://github.com/honwen/luci-app-aliddns)
- [pymumu/luci-app-smartdns](https://github.com/pymumu/luci-app-smartdns)
- [tty228/luci-app-serverchan](https://github.com/tty228/luci-app-serverchan)
- [Lienol/openwrt-package](https://github.com/Lienol/openwrt-package)
- [vernesong/OpenClash.git](https://github.com/vernesong/OpenClash.git)
- [jerrykuku/luci-app-jd-dailybonus](https://github.com/jerrykuku/luci-app-jd-dailybonus.git)