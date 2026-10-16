# ZN-M2 OpenWrt（官方源移植）

[![Build ZN-M2](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml/badge.svg)](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml)

把兆能 M2（ZN-M2）移植进**官方** [openwrt/openwrt](https://github.com/openwrt/openwrt) 的 `openwrt-25.12` 分支，用 GitHub Actions 云编译出可刷固件。
官方树里没有这台设备：本仓自带 4 个补丁 + 设备树 + 树外内核模块，不依赖 lede / immortalwrt / LiBwrt / kiddin9 / openwrt.ai 等下游树。

## 支持设备

兆能 M2（ZN-M2，`zn,m2`）：Qualcomm IPQ6000（IPQ6018），目标 `qualcommax/ipq60xx`，4×千兆口（3 LAN + 1 WAN），NAND 128k 块 / 2048 页。

## 快速开始

**① GitHub Actions（推荐，零本地环境）**

1. fork 本仓，或把它推成自己的 **public** 仓（public 仓 Actions 免费、不限时长）。
2. Actions → `Build ZN-M2 (qualcommax/ipq60xx)` → Run workflow（源码分支默认 `openwrt-25.12`）。
3. 构建产物在 Artifacts（保留 14 天）；手动与定时构建同时发 Release（tag `zn-m2-<时间戳>`）。工作流每周一 03:17（UTC+8）会跟上游重建。

**② 本地编译**（Linux，依赖装法见工作流里的「装编译依赖」步骤；假设本仓在 `zn-m2-openwrt/`）

```sh
git clone --depth 1 -b openwrt-25.12 https://github.com/openwrt/openwrt
sh zn-m2-openwrt/apply.sh openwrt        # 幂等：4 补丁 + BDF + packages/*
cd openwrt
cp ../zn-m2-openwrt/configs/feeds.conf feeds.conf
./scripts/feeds update -a && ./scripts/feeds install -a
cp ../zn-m2-openwrt/configs/zn_m2.config .config && make defconfig
export FORCE_UNSAFE_CONFIGURE=1          # 以 root 编译必加：GNU tar 的 configure 拒绝 root
make -j"$(nproc)" download && make -j"$(nproc)" V=s
```

## 产物与刷机

产物在 `bin/targets/qualcommax/ipq60xx/`：

- `*zn_m2*squashfs-nand-factory.ubi` —— 原厂 u-boot 下首次刷入
- `*zn_m2*squashfs-nand-sysupgrade.bin` —— 已在跑 OpenWrt 时升级
- `*zn_m2*initramfs-uImage.itb` —— 只用于试启动 / 救援，不是刷机包

1. 先 `sysupgrade -b` 备份，并留一份当前固件的 sysupgrade 包当回滚基线。
2. 先刷 initramfs 试启动（认网口、认无线），没问题再 sysupgrade。
3. **不要**动 `0:mibib` / `0:appsbl` / `0:cdt`：`factory.ubi` 只覆写 `rootfs`，改引导分区才是变砖路径（硬改内存需先刷 CDT 并换扩容版 u-boot）。

> `openwrt-25.12` 的包管理是 **apk** 而非 opkg，现成的 `.ipk` 装不上 —— 这也是 `kmod-rkp-ipid` 必须跟固件一起编的原因。

## 本仓改了什么

- `patches/0001` 设备 profile：`qualcommax/image/ipq60xx.mk` 新增 `Device/zn_m2`（FitImage + UbiFit、`BLOCKSIZE 128k`、`PAGESIZE 2048`、`DEVICE_DTS ipq6018-m2`、`DEVICE_DTS_CONFIG config@cp03-c1`、`DEVICE_PACKAGES ipq-wifi-zn_m2`）。
- `patches/0002` base-files：`zn,m2` 的 LED（`01_leds`）、网络（`02_network`，`lan1 lan2 lan3` + `wan`）、校准数据（`11-ath11k-caldata`，`0:art` 偏移 `0x1000` 长度 `0x10000`）、升级路径（`platform.sh` → `nand_do_upgrade`）。
- `patches/0003` 新 DTS：新增 `ipq6018-m2.dts`，骨架取自官方 `ipq6000-360v6.dts`，硬件取值来自设备实测导出的 DTB 反编译：512M 内存布局、`qcom,smem-part`、PHY 0/1/3/4、LAN = `ESS_PORT1|2|4` / WAN = `ESS_PORT5`、`fw-memory-mode = <1>`、LED 58/73/74/37/35/70、按键 60/9。
- `patches/0004` ipq-wifi 板级数据：`ALLWIFIBOARDS` 加入 `zn_m2`、生成 `ipq-wifi-zn_m2` 包，并用 `Build/Prepare` 把仓内 BDF 拷进 `PKG_BUILD_DIR`。
- `packages/rkp-ipid`：树外 `kmod-rkp-ipid`，vermagic 绑内核所以必须与固件同一次编译；install 钩子写死 `mark_capture=0x100 mark_random=0x200`（上游 `AUTOLOAD` 生成的是裸模块，参数会落到内核默认的 `0x10/0x20`）。

## 文件清单

- `apply.sh` —— 把补丁 + BDF + `packages/*` 幂等打进一份官方树
- `patches/`、`files/` —— 4 个补丁；`ipq6018-m2.dts` 副本与无线 BDF（65632 B，取自设备 `0:art` 偏移 `0x1000` 起的 64 KiB 校准区，md5 `535d125fb6a7a84174a13974f7f7323a`）
- `packages/rkp-ipid/` —— 树外内核模块
- `configs/` —— 构建种子 `zn_m2.config` + 精简 `feeds.conf`（只 packages + luci）
- `.github/workflows/build.yml` —— Actions 云编译
- `refs/` —— 设备实测 DTB 反编译、官方与下游参考件；只作取证，不参与构建

## 状态

**已验证**：4 个补丁在 `openwrt-25.12@6790b061252e34b97c8d7ad646dbb84b186a1445` 上干净应用、清空重放结果一致；DTS 引用的 10 个 label 在内核 6.12 的 `ipq6018.dtsi` 里都存在（`wifi` 节点由官方 `0906-arm64-dts-qcom-ipq6018-add-wifi-node.patch` 提供）；无线 BDF 的 md5 `535d125fb6a7a84174a13974f7f7323a`（65632 B）与设备实测一致；装完 feeds 后 `make defconfig` 退出码 0，`CONFIG_TARGET_qualcommax_ipq60xx_DEVICE_zn_m2=y`、`CONFIG_PACKAGE_ipq-wifi-zn_m2=y`、平台默认包与种子里的勾选项全部被选中（0 丢弃）；引导侧 `0:appsbl` 分区自带的 FIT 配置名列表里含 `config@cp03-c1`，`0:appsblenv` 里 `ethaddr`~`eth4addr` 齐全（对应 dp1/dp2/dp4/dp5 的 MAC 注入）；512MB 内存布局对 256MB 机器不越界，1GB 硬改也不受影响（根 `memory` 节点由 u-boot 注入，DTS 里没有）。

**未验证**：**尚未完成过一次端到端编译，也从未上机刷过**，本仓的首次端到端验证会发生在 CI；`kmod-rkp-ipid` 没有编译验证过（工作流对它只告警不中断）；wlan LED 的 netdev 名（`wlan0`=5G / `wlan1`=2.4G）是照同子目标 `yuncore,fap650` 抄的；MAC 若不对，需要在 `02_network` 里加 `mtd_get_mac_ascii 0:appsblenv ethaddr`；256MB 机器刷 64 位固件 + WiFi 的真实风险是内存占用，不是设备树。
