include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
 
PKG_NAME:=rkp-ipid
PKG_RELEASE:=2
 
include $(INCLUDE_DIR)/package.mk

define KernelPackage/rkp-ipid
	SUBMENU:=Other modules
	TITLE:=rkp-ipid
	FILES:=$(PKG_BUILD_DIR)/rkp-ipid.ko
	KCONFIG:=
endef

# 故意不用 AUTOLOAD：$(call AutoLoad,99,rkp-ipid) 只会生成一行裸的 "rkp-ipid"，
# 内核就用默认 mark_capture=0x10 / mark_random=0x20；而本项目的 iot 规则用的是
# 0x100 / 0x200（现网 /etc/modules.d/99-rkp-ipid 就是这一行），所以必须写死参数。
#
# 注意：验证参数是否真的生效要看 dmesg（模块加载时会打印 mark_capture/mark_random），
# 手工 insmod 才传得进参数，busybox 的 modprobe 会把参数悄悄丢掉。
define KernelPackage/rkp-ipid/install
	$(INSTALL_DIR) $(1)/etc/modules.d
	echo "rkp-ipid mark_capture=0x100 mark_random=0x200" > $(1)/etc/modules.d/99-rkp-ipid
endef

EXTRA_KCONFIG:= \
	CONFIG_RKP_IPID=m

EXTRA_CFLAGS:= \
	$(patsubst CONFIG_%, -DCONFIG_%=1, $(patsubst %=m,%,$(filter %=m,$(EXTRA_KCONFIG)))) \
	$(patsubst CONFIG_%, -DCONFIG_%=1, $(patsubst %=y,%,$(filter %=y,$(EXTRA_KCONFIG)))) \
	-DVERSION=$(PKG_RELEASE)

MAKE_OPTS:=$(KERNEL_MAKE_FLAGS) \
	M="$(PKG_BUILD_DIR)" \
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	$(EXTRA_KCONFIG)

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" $(MAKE_OPTS) modules
endef

$(eval $(call KernelPackage,rkp-ipid))
