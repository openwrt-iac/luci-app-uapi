# SPDX-License-Identifier: MIT
#
# LuCI app for managing uapi (https://github.com/openwrt-iac/uapi).

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for uapi (native REST API for OpenWrt)
LUCI_DEPENDS:=+luci-base +uapi
LUCI_PKGARCH:=all

# Version is sourced from the VERSION file so the git tag (vX.Y.Z), the
# CHANGELOG heading, and the apk version stay in lockstep. PKG_RELEASE bumps
# only for packaging-only changes against an unchanged VERSION.
PKG_VERSION:=$(shell sed -n '1p' $(CURDIR)/VERSION)
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Guy Godfroy <guy.godfroy@ovhcloud.com>

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature
