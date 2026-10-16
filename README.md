# ZN-M2 官方源移植

把兆能 M2（IPQ6000）移植进官方 `openwrt/openwrt`，GitHub Actions 出固件，不依赖任何下游树。

- 编译相关文件只放本目录；**不在本机编译**（本机根分区只读、无 docker，实测编不动）。
- 硬件取值全部来自现网 DTB，取证文件在 `refs/`。

## 目录

```
apply.sh          # 把移植打进一份官方树（幂等）：4 补丁 + BDF + packages/*
patches/          # 全部针对 openwrt-25.12
files/            # ipq6018-m2.dts 副本 + board-zn_m2.bin.ipq6018（无线 BDF，65632B）
packages/         # 树外内核模块 kmod-rkp-ipid
configs/          # zn_m2.config（构建种子）+ feeds.conf（精简 feeds）
.github/workflows/build.yml   # Actions 工作流
refs/             # 现网 DTB/DTS、官方与 lede 的参考文件、defconfig 解析基线
```

## 用法

**Actions（推荐）**：本目录就是一个独立仓 —— 推成 public 仓，Actions → Build ZN-M2 → Run workflow。

**另一台能 `apt install` 的 Linux**：

```sh
git clone --depth 1 -b openwrt-25.12 https://github.com/openwrt/openwrt
sh apply.sh openwrt
cd openwrt
cp ../configs/feeds.conf feeds.conf
./scripts/feeds update -a && ./scripts/feeds install -a
cp ../configs/zn_m2.config .config && make defconfig
make -j"$(nproc)" download
make -j"$(nproc)" V=s          # root 编译先 export FORCE_UNSAFE_CONFIGURE=1
```

产物在 `bin/targets/qualcommax/ipq60xx/`：`*-factory.ubi` 原厂 u-boot 首刷、
`*-sysupgrade.bin` 升级用、`*-initramfs-uImage.itb` 只用于试启动/救援（不是刷机包）。

## 改了什么

- `0001` `qualcommax/image/ipq60xx.mk`：新增 `Device/zn_m2`（FitImage+UbiFit、`BLOCKSIZE 128k`、
  `PAGESIZE 2048`、`DEVICE_DTS ipq6018-m2`、`DEVICE_DTS_CONFIG config@cp03-c1`、`DEVICE_PACKAGES ipq-wifi-zn_m2`）
- `0002` `ipq60xx/base-files`：`zn,m2` 的 LED / 网络 / `11-ath11k-caldata`（`0:art` 0x1000 0x10000）/ `platform.sh` 升级路径
- `0003` 新增 `ipq6018-m2.dts`：骨架取自官方 `ipq6000-360v6.dts`，值取自现网 DTB
  （512M 内存、`qcom,smem-part`、PHY 0/1/3/4、`ESS_PORT1|2|4`=LAN + `ESS_PORT5`=WAN、`fw-memory-mode = <1>`、
  LED 58/73/74/37/35/70、按键 60/9；不能照抄 lede 的 `ipq6018-cmiot.dtsi`，它 include 的三个 dtsi 官方树里没有）
- `0004` `ipq-wifi`：`ALLWIFIBOARDS` 加 `zn_m2`、生成 `ipq-wifi-zn_m2` 包，并用 `Build/Prepare` 把本地 BDF 拷进 `PKG_BUILD_DIR`
- `packages/rkp-ipid`：树外 `kmod-rkp-ipid`，vermagic 绑内核所以必须跟固件同编；install 钩子写死
  `mark_capture=0x100 mark_random=0x200`（上游 `AUTOLOAD` 生成的是裸模块，参数会取内核默认 `0x10/0x20`）

## 状态

已验证：4 个补丁在 `openwrt-25.12@6790b061252e34b97c8d7ad646dbb84b186a1445` 上干净应用并可清空重放；
DTS 引用的 10 个 label 在内核 6.12 里都存在（`wifi` 由官方 `0906-...add-wifi-node.patch` 提供）；
BDF md5 与现网一致；`make defconfig` 退出码 0，设备 profile 与全部勾选项都被选中。

未验证：没编完过、没刷过；`kmod-rkp-ipid` 没真编过（工作流里对它有专门告警）；
原厂 u-boot 认不认 `config@cp03-c1`；MAC 若随机改走 `mtd_get_mac_ascii 0:appsblenv ethaddr`；
wlan LED 的 netdev 名照同子目标 `yuncore,fap650` 抄的；DTS 按 512MB 写死（256MB/硬改 1GB 要改那行）。

## 刷机顺序

1. `sysupgrade -b` 备份，留一份现网 Kwrt 的 sysupgrade 包当回滚基线。
2. 先刷 initramfs 试启动，能认网口和无线再动 sysupgrade。
3. 起来后 `sh Backup/restore.sh` 推回抗检测栈（见 `Backup/重装清单.md`）。

> 25.12 的包管理是 **apk**，现网那些 `.ipk` 装不上 —— 这是 rkp-ipid 必须一起编的原因。
