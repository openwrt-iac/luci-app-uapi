#!/bin/sh
# Build the luci-app-uapi apk against a pinned OpenWrt SDK.
#
# Two wrinkles drive the shape of this script:
#   1. The Makefile does `include ../../luci.mk`, which only resolves inside the
#      luci feed tree, so we copy the package into feeds/luci/applications/.
#   2. An apk is only kept in bin/ when its package is SELECTED, and selecting
#      luci-app-uapi requires its `uapi` dependency to exist as a known package.
#      The real uapi lives in a sibling repo and needs its own staging step, so
#      we drop in a tiny build-time STUB named `uapi` purely to satisfy the
#      dependency symbol. The stub is never published; we only ship the
#      luci-app-uapi apk, whose `depends: uapi` metadata is correct regardless.
#
# Inputs (env):
#   SDK_URL     full URL of the SDK tarball (.tar.zst)         [required]
#   SDK_SHA256  expected sha256 of that tarball                [required]
#   SDK_DIR     extract/cache location (default: $REPO/.sdk)
# Output:
#   prints the built apk's absolute path as the last stdout line; also writes
#   `apk=<path>` to $GITHUB_OUTPUT when running under GitHub Actions.
set -eu

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
SDK_DIR=${SDK_DIR:-"$REPO_DIR/.sdk"}
: "${SDK_URL:?SDK_URL required}"
: "${SDK_SHA256:?SDK_SHA256 required}"

TARBALL=$(basename "$SDK_URL")

if [ ! -d "$SDK_DIR/staging_dir" ]; then
	echo "Downloading SDK: $SDK_URL"
	mkdir -p "$SDK_DIR"
	curl -fsSL -o "/tmp/$TARBALL" "$SDK_URL"
	echo "$SDK_SHA256  /tmp/$TARBALL" | sha256sum --check -
	tar --use-compress-program=unzstd -xf "/tmp/$TARBALL" -C "$SDK_DIR" --strip-components=1
	rm -f "/tmp/$TARBALL"
fi

cd "$SDK_DIR"

./scripts/feeds update -a >/dev/null 2>&1 || ./scripts/feeds update -a

# Build-time stub satisfying the `uapi` dependency (see header).
mkdir -p package/uapi-dep-stub
cat > package/uapi-dep-stub/Makefile <<'STUB'
include $(TOPDIR)/rules.mk
PKG_NAME:=uapi
PKG_VERSION:=0
PKG_RELEASE:=1
include $(INCLUDE_DIR)/package.mk
define Package/uapi
  SECTION:=net
  CATEGORY:=Network
  TITLE:=uapi (CI build-dependency stub, do not publish)
endef
define Package/uapi/description
 Empty stub so luci-app-uapi can be selected and built in CI. Not the real uapi.
endef
define Build/Compile
endef
define Package/uapi/install
endef
$(eval $(call BuildPackage,uapi))
STUB

# Inject the package into the luci feed tree (copy only what the build needs).
DEST="feeds/luci/applications/luci-app-uapi"
rm -rf "$DEST"
mkdir -p "$DEST"
for item in Makefile VERSION htdocs root po; do
	[ -e "$REPO_DIR/$item" ] && cp -r "$REPO_DIR/$item" "$DEST/"
done

# Reindex so the freshly-added package is visible, then wire it into the build.
./scripts/feeds update -i >/dev/null 2>&1
./scripts/feeds install -p luci luci-app-uapi >/dev/null

# Select the package so its apk is kept in bin/ (defconfig pulls in the deps).
grep -q '^CONFIG_PACKAGE_luci-app-uapi=y' .config 2>/dev/null \
	|| echo 'CONFIG_PACKAGE_luci-app-uapi=y' >> .config
make defconfig >/dev/null

if ! grep -q '^CONFIG_PACKAGE_luci-app-uapi=y' .config; then
	echo "ERROR: luci-app-uapi could not be selected (dependency unresolved)." >&2
	exit 1
fi

make package/luci-app-uapi/compile V=s

APK=$(find bin -name 'luci-app-uapi-*.apk' | head -1)
[ -n "$APK" ] || { echo "ERROR: no luci-app-uapi apk produced" >&2; exit 1; }
APK_ABS="$SDK_DIR/$APK"

echo "Built: $APK_ABS"
sha256sum "$APK_ABS"
[ -n "${GITHUB_OUTPUT:-}" ] && echo "apk=$APK_ABS" >> "$GITHUB_OUTPUT"
echo "$APK_ABS"
