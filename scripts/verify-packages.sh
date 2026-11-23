#!/usr/bin/env bash
set -euo pipefail

required=(
  luci-app-openclash luci-app-diskman luci-app-ttyd luci-app-samba4
  samba4-server ttyd block-mount automount kmod-fs-ext4 kmod-fs-vfat
  kmod-fs-exfat
)
failed=0
for pkg in "${required[@]}"; do
  if grep -Fqx "CONFIG_PACKAGE_${pkg}=y" .config; then
    echo "OK: ${pkg}"
  else
    echo "ERROR: ${pkg} missing after make defconfig"
    failed=1
  fi
done

# S20P identity and vendor-specific Wi-Fi / acceleration selections.
for sym in \
  CONFIG_TARGET_mediatek=y \
  CONFIG_TARGET_mediatek_filogic=y \
  CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_clx_s20p=y \
  CONFIG_PACKAGE_kmod-mt_wifi=y \
  CONFIG_PACKAGE_kmod-mediatek_hnat=y \
  CONFIG_PACKAGE_kmod-warp=y \
  CONFIG_MTK_CHIP_MT7986=y \
  CONFIG_MTK_MT_WIFI_DRIVER_VERSION_7673=y \
  CONFIG_MTK_WARP_V2=y \
  CONFIG_PACKAGE_luci-app-mtwifi-cfg=y \
  CONFIG_PACKAGE_luci-app-turboacc-mtk=y; do
  if grep -Fqx "$sym" .config; then
    echo "OK: preserved ${sym}"
  else
    echo "ERROR: required S20P setting missing: ${sym}"
    failed=1
  fi
done

# Confirm legacy SMB implementation is not selected.
for pkg in luci-app-ksmbd ksmbd-hotplug ksmbd-avahi-service kmod-fs-ksmbd; do
  if grep -Fqx "CONFIG_PACKAGE_${pkg}=y" .config; then
    echo "ERROR: conflicting legacy SMB package selected: ${pkg}"
    failed=1
  fi
done

exit "$failed"
