# ZN-M2 OpenWrt

[![Build ZN-M2](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml/badge.svg)](https://github.com/lhxyzCJ/zn-m2-openwrt/actions/workflows/build.yml)

## 支持设备

兆能 M2 Qualcomm IPQ6000（IPQ6018）

## 编译

**GitHub Actions**：fork 本仓 → Actions → Run workflow。

- `mode=firmware`（默认）：编完整固件。构建会拿最终镜像的 `.manifest` 逐项核对
  `configs/zn_m2.config` 里的 `CONFIG_PACKAGE_*=y`，缺一个就失败。
- `mode=packages`：只编同一份 config 选中的包（含 `kmod-nft-queue`），不生成镜像；
  `upstream` 填与固件相同的分支/tag/SHA。仍要编 toolchain + 内核（约 1 小时），
  只是省掉 rootfs/镜像阶段。

固件产物在 Artifacts（14 天）和 Release（tag `zn-m2-<时间戳>`）；packages 产物是
`zn-m2-packages-<时间戳>.tar.gz`，内含 `bin/packages` 与 `bin/targets/.../packages` 的 `.apk`。
**同一个 Release 里还有 4 个 `.adb` 包索引**（`base/luci/packages/target-packages.adb`），
那才是"能装"的 apk 源——与本机内核同一次构建，kmod 的 vermagic/hash 才匹配。
现网 `/etc/apk/repositories.d/customfeeds.list`（由 router 上 `/root/pkgfeed.sh` 生成）就指向
`releases/download/zn-m2-<时间戳>/*.adb`；只拿 tar.gz 离线装包会缺内核身份校验。

**单独编包的边界**：kmod 依赖 `kernel=6.18.55~<内核 config hash>-r1`。改
`configs/zn_m2.config`（比如刚加 `kmod-nft-queue`）会改 hash，单独编的 kmod 装不进用旧
config 编的固件；签名 key 也每次构建不同。要给现网补包，最稳的是重刷新固件；刷入后如果还要
装额外包，用同一次 firmware 构建产出的 `zn-m2-packages-*.tar.gz`（同 key、同 vermagic）；
镜像没内置该 key 时，装包加 `apk add --allow-untrusted`。

**本地**（在仓库根目录）：

```sh
git clone --depth 1 -b main https://github.com/openwrt/openwrt
sh apply.sh openwrt
cd openwrt
cp ../configs/feeds.conf feeds.conf
./scripts/feeds update -a && ./scripts/feeds install -a
cp ../configs/zn_m2.config .config && make defconfig
export FORCE_UNSAFE_CONFIGURE=1
make -j"$(nproc)" download && make -j"$(nproc)" V=s
```

## 产物

固件在 `bin/targets/qualcommax/ipq60xx/`：

- `openwrt-qualcommax-ipq60xx-zn_m2-squashfs-factory.ubi`
- `openwrt-qualcommax-ipq60xx-zn_m2-squashfs-sysupgrade.bin`
- `openwrt-qualcommax-ipq60xx-zn_m2-initramfs-uImage.itb`
- `openwrt-qualcommax-ipq60xx-zn_m2.manifest`

packages 在 `bin/packages/aarch64_cortex-a53/`（feed 包）和
`bin/targets/qualcommax/ipq60xx/packages/`（kmods）。
