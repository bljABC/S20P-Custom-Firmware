
#!/usr/bin/env bash
set -euo pipefail

# Keep the upstream S20P hardware profile intact. Only prune optional LuCI
# applications/themes and explicitly identified unrelated services.
[[ -s .config ]] || { echo 'ERROR: .config is missing'; exit 1; }

tmp="$(mktemp)"
while IFS= read -r line; do
    # Remove all selected LuCI apps first; the allow-list is re-added below.
    if [[ "$line" =~ ^CONFIG_PACKAGE_(luci-app-[A-Za-z0-9_-]+|luci-theme-[A-Za-z0-9_-]+)=y$ ]]; then
        pkg="${BASH_REMATCH[1]}"
        case "$pkg" in
            luci-app-firewall|luci-app-mtwifi-cfg|luci-app-turboacc-mtk|luci-app-uhttpd) ;;
            *) printf '# CONFIG_PACKAGE_%s is not set\n' "$pkg" >> "$tmp"; continue ;;
        esac
    fi

    # Remove the old SMB implementation and explicitly unwanted add-ons.
    if [[ "$line" =~ ^CONFIG_PACKAGE_(ksmbd[^=]*|autoksmbd|honk|cloudflared|dockerman|easytier|rtp2httpd|msmtp|msmtp-mta|mutt|acme-acmesh-dnsapi)=y$ ]]; then
        printf '# CONFIG_PACKAGE_%s is not set\n' "${BASH_REMATCH[1]}" >> "$tmp"
        continue
    fi

    printf '%s\n' "$line" >> "$tmp"
done < .config
mv "$tmp" .config

# Set Kconfig symbols deterministically (replace old y/n/not-set entries).
set_symbol() {
    local symbol="$1" value="$2"
    sed -i -E "/^(CONFIG_${symbol}=|# CONFIG_${symbol} is not set)/d" .config

    if [[ "$value" == y ]]; then
        printf 'CONFIG_%s=y\n' "$symbol" >> .config
    else
        printf '# CONFIG_%s is not set\n' "$symbol" >> .config
    fi
}

# Requested applications.
for pkg in \
    luci-app-openclash luci-app-diskman luci-app-ttyd luci-app-samba4 \
    samba4-server ttyd; do
    set_symbol "PACKAGE_${pkg}" y
done

# Runtime dependencies required by OpenClash and Diskman.
for pkg in \
    bash curl ruby ruby-yaml unzip xfs-mkfs; do
    set_symbol "PACKAGE_${pkg}" y
done

# Keep the standard mount-point backend and common USB-disk filesystems.
for pkg in \
    block-mount automount blkid lsblk fdisk gdisk dosfstools \
    kmod-fs-ext4 e2fsprogs kmod-fs-vfat kmod-fs-exfat exfat-mkfs \
    kmod-fs-f2fs f2fs-tools f2fsck mkf2fs blockdev losetup; do
    set_symbol "PACKAGE_${pkg}" y
done

set_symbol 'DEFAULT_block-mount' y
set_symbol 'DEFAULT_automount' y

# Samba4 replaces ksmbd; never ship both SMB server implementations.
for pkg in \
    luci-app-ksmbd ksmbd-hotplug ksmbd-avahi-service kmod-fs-ksmbd; do
    set_symbol "PACKAGE_${pkg}" n
done

# Optional standalone luci-app-mount is not assumed. The supported mount UI
# is the standard LuCI System -> Mount Points page backed by block-mount.
if find feeds package -path '*/luci-app-mount/Makefile' -print -quit 2>/dev/null | grep -q .; then
    set_symbol 'PACKAGE_luci-app-mount' y
    echo 'Found optional luci-app-mount package; enabled it.'
else
    echo 'No standalone luci-app-mount package; using LuCI System -> Mount Points + block-mount.'
fi
