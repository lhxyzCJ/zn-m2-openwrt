# ZN-M2 OpenWrt（官方源移植）

[![Build ZN-M2](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml/badge.svg)](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml)

把兆能 M2（ZN-M2）移植进**官方** [openwrt/openwrt](https://github.com/openwrt/openwrt) 的 `openwrt-25.12` 分支，用 GitHub Actions 云编译固件。本仓自带 4 个补丁（设备 profile / base-files / 设备树 / ipq-wifi 板级数据）与树外 `kmod-rkp-ipid`，不依赖 lede / immortalwrt 等下游树。

## 支持设备

兆能 M2（`zn,m2`）：Qualcomm IPQ6000（IPQ6018），目标 `qualcommax/ipq60xx`，4×千兆口（3 LAN + 1 WAN）。

## 编译

**GitHub Actions**：fork 本仓 → Actions → Run workflow。产物在 Artifacts（14 天）和 Release（tag `zn-m2-<时间戳>`）。

**本地**（在仓库根目录）：

```sh
git clone --depth 1 -b openwrt-25.12 https://github.com/openwrt/openwrt
sh apply.sh openwrt
cd openwrt
cp ../configs/feeds.conf feeds.conf
./scripts/feeds update -a && ./scripts/feeds install -a
cp ../configs/zn_m2.config .config && make defconfig
export FORCE_UNSAFE_CONFIGURE=1
make -j"$(nproc)" download && make -j"$(nproc)" V=s
```

## 产物与刷机

产物在 `bin/targets/qualcommax/ipq60xx/`：

- `*zn_m2*squashfs-nand-factory.ubi` —— 原厂固件首次刷入
- `*zn_m2*squashfs-nand-sysupgrade.bin` —— 已在跑 OpenWrt 时升级
- `*zn_m2*initramfs-uImage.itb` —— 试启动 / 救援

1. 刷前备份原机固件与配置。
2. 不要动 `0:mibib` / `0:appsbl` / `0:cdt`。
