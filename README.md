# ZN-M2 OpenWrt（官方源移植）

[![Build ZN-M2](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml/badge.svg)](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml)

把兆能 M2（ZN-M2）移植进**官方** [openwrt/openwrt](https://github.com/openwrt/openwrt) 的 `openwrt-25.12` 分支，用 GitHub Actions 云编译出可刷固件；本仓自带 4 个补丁（设备 profile / base-files / 设备树 / ipq-wifi 板级数据）外加树外 `kmod-rkp-ipid`，不依赖 lede / immortalwrt 等下游树。

## 支持设备

兆能 M2（`zn,m2`）：Qualcomm IPQ6000（IPQ6018），目标 `qualcommax/ipq60xx`，4×千兆口（3 LAN + 1 WAN）。

## 快速开始

**① GitHub Actions（推荐）**

1. fork 本仓，或把它推成自己的 public 仓（Actions 免费、不限时长）。
2. Actions → `Build ZN-M2 (qualcommax/ipq60xx)` → Run workflow（源码分支默认 `openwrt-25.12`）。
3. 产物在 Artifacts（保留 14 天），同时以 tag `zn-m2-<时间戳>` 发 Release。

**② 本地编译**（Linux，依赖装法见工作流的「装编译依赖」步骤；假设本仓在 `zn-m2-openwrt/`）

```sh
git clone --depth 1 -b openwrt-25.12 https://github.com/openwrt/openwrt
sh zn-m2-openwrt/apply.sh openwrt
cd openwrt
cp ../zn-m2-openwrt/configs/feeds.conf feeds.conf
./scripts/feeds update -a && ./scripts/feeds install -a
cp ../zn-m2-openwrt/configs/zn_m2.config .config && make defconfig
export FORCE_UNSAFE_CONFIGURE=1
make -j"$(nproc)" download && make -j"$(nproc)" V=s
```

## 产物与刷机

产物在 `bin/targets/qualcommax/ipq60xx/`：`*zn_m2*squashfs-nand-factory.ubi`（首次刷入）、`*zn_m2*squashfs-nand-sysupgrade.bin`（已在跑 OpenWrt 时升级）、`*zn_m2*initramfs-uImage.itb`（仅试启动 / 救援）。

1. 备份配置，并留一份当前固件的 sysupgrade 包当回滚基线。
2. 先刷 initramfs 试启动（认网口、认无线），没问题再 sysupgrade。
3. 不要动 `0:mibib` / `0:appsbl` / `0:cdt`：`factory.ubi` 只覆写 `rootfs`。
