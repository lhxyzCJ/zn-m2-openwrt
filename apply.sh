#!/bin/sh
# 把 ZN M2（兆能 M2 / IPQ6000）移植应用到一份官方 OpenWrt 源码树。
#
#   sh apply.sh /path/to/openwrt
#
# 幂等：已经打过的补丁会被识别并跳过；部分打过则报错退出（不会打歪）。
# 需要官方 openwrt-25.12 分支（main 上 DTS/绑定有差异，未验证）。

set -e

TREE=${1:-}
if [ -z "$TREE" ] || [ ! -d "$TREE" ]; then
	echo "用法: sh $0 /path/to/openwrt" >&2
	exit 1
fi

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TREE=$(CDPATH= cd -- "$TREE" && pwd)

command -v git >/dev/null 2>&1 || { echo "需要 git（打补丁用）" >&2; exit 1; }

[ -f "$TREE/rules.mk" ] || { echo "$TREE 看起来不是 OpenWrt 源码树" >&2; exit 1; }

for p in "$HERE"/patches/*.patch; do
	name=$(basename "$p")
	if git -C "$TREE" apply --check "$p" 2>/dev/null; then
		echo "==> 应用 $name"
		git -C "$TREE" apply "$p"
	elif git -C "$TREE" apply --reverse --check "$p" 2>/dev/null; then
		echo "==> 跳过 $name（已应用）"
	else
		echo "!!! $name 既打不上、也不是已应用状态" >&2
		echo "    多半是源码树版本不对（本移植针对 openwrt-25.12），或该文件被改过。" >&2
		exit 1
	fi
done

# 无线板级数据（BDF）是二进制，不进补丁，单独拷
BDF="$HERE/files/package/firmware/ipq-wifi/src/board-zn_m2.bin.ipq6018"
DST="$TREE/package/firmware/ipq-wifi/src/board-zn_m2.bin.ipq6018"
EXPECT=535d125fb6a7a84174a13974f7f7323a

got=$(md5sum "$BDF" | cut -d' ' -f1)
if [ "$got" != "$EXPECT" ]; then
	echo "!!! BDF 校验失败: $got != $EXPECT" >&2
	exit 1
fi

mkdir -p "$(dirname "$DST")"
cp "$BDF" "$DST"
echo "==> board-zn_m2.bin.ipq6018 就位（md5 $got，65632 字节）"

# 树外包（目前只有 rkp-ipid 这个内核模块）：拷进 package/
if [ -d "$HERE/packages" ]; then
	for d in "$HERE"/packages/*/; do
		[ -d "$d" ] || continue
		name=$(basename "$d")
		dest="$TREE/package/$name"
		if [ -e "$dest" ]; then
			echo "==> package/$name 已存在，跳过（要更新请自行替换）"
		else
			cp -a "$d" "$dest"
			echo "==> 装入 package/$name（树外内核模块）"
		fi
	done
fi

cat <<EOF

移植已应用。接下来（本机编不动，走 Actions 或另一台能装包的 Linux，见 README.md）：

  cd $TREE
  cp $HERE/configs/feeds.conf feeds.conf      # 精简 feeds：只 packages + luci
  ./scripts/feeds update -a && ./scripts/feeds install -a
  cp $HERE/configs/zn_m2.config .config
  make defconfig                      # 确认选中 DEVICE_zn_m2 与所需包
  make -j\$(nproc) download
  make -j\$(nproc) V=s

  以 root 编译时先 export FORCE_UNSAFE_CONFIGURE=1（GNU tar 的 configure 会拒绝 root）。

产物（bin/targets/qualcommax/ipq60xx/）：
  *-zn_m2-squashfs-nand-sysupgrade.bin   # 已跑 OpenWrt 时用
  *-zn_m2-squashfs-nand-factory.ubi      # 原厂 u-boot 首次刷入用
  *-zn_m2-initramfs-uImage.itb           # 只用于试启动 / 救援

第一次务必先刷 initramfs 确认能起来，再动 sysupgrade（见同目录 README.md）。
EOF
