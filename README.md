# ZN-M2 OpenWrt

[![Build ZN-M2](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml/badge.svg)](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml)

## 支持设备

兆能 M2 Qualcomm IPQ6000（IPQ6018）

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

## 产物

产物在 `bin/targets/qualcommax/ipq60xx/`：

- `*zn_m2*squashfs-nand-factory.ubi`
- `*zn_m2*squashfs-nand-sysupgrade.bin`
- `*zn_m2*initramfs-uImage.itb`
