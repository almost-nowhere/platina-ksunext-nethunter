#!/system/bin/sh

# KernelSU adapter for Kali's official generic ARM64 full installer.
# The official archive is kept unchanged and is used as the payload source.

ORIGINAL_ZIP=/sdcard/Download/kali-nethunter-2026.2-generic-arm64-full.zip
EXPECTED_SHA256=b09756fab7939092bcf7c6242c360022426aa85b435a3285daee36a608bf8880
KSU_BUSYBOX=/data/adb/ksu/bin/busybox
NHSYS=/data/local/nhsystem

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$*"; }
command -v abort >/dev/null 2>&1 || abort() { ui_print "! $*"; exit 1; }

print() {
    ui_print "$*"
}

set_item_perm() {
    chown "$2:$3" "$1" 2>/dev/null || true
    chmod "$4" "$1" 2>/dev/null || true
    chcon "${5:-u:object_r:system_file:s0}" "$1" 2>/dev/null || true
}

set_tree_perm() {
    [ -e "$1" ] || return 0
    find "$1" -type d -exec chown "$2:$3" {} + 2>/dev/null || true
    find "$1" -type d -exec chmod "$4" {} + 2>/dev/null || true
    find "$1" \( -type f -o -type l \) -exec chown "$2:$3" {} + 2>/dev/null || true
    find "$1" -type f -exec chmod "$5" {} + 2>/dev/null || true
    chcon -R "${6:-u:object_r:system_file:s0}" "$1" 2>/dev/null || true
}

install_apk() {
    APK="$1"
    LABEL="$2"
    if [ ! -f "$APK" ]; then
        ui_print "! Missing $LABEL"
        return 1
    fi
    ui_print "- Installing $LABEL"
    pm install -r -g "$APK" >/dev/null 2>&1 || {
        ui_print "! Failed to install $LABEL"
        return 1
    }
}

ui_print "*******************************"
ui_print " Kali NetHunter KSU adapter"
ui_print "*******************************"

[ -x "$KSU_BUSYBOX" ] || abort "KernelSU BusyBox not found"
[ -f "$ORIGINAL_ZIP" ] || abort "Official NetHunter ZIP not found: $ORIGINAL_ZIP"

ui_print "- Verifying official NetHunter archive"
ACTUAL_SHA256=$(sha256sum "$ORIGINAL_ZIP" | awk '{print $1}')
[ "$ACTUAL_SHA256" = "$EXPECTED_SHA256" ] || abort "Official ZIP checksum mismatch"

AVAILABLE_KB=$(df -Pk /data | awk 'END {print $4}')
[ -n "$AVAILABLE_KB" ] || abort "Unable to determine free data space"
[ "$AVAILABLE_KB" -ge 12582912 ] || abort "At least 12 GiB free space is required"

# KSU has already created MODPATH for this adapter. Populate it with every
# official module component except the Magisk-only installer and the large
# rootfs, which is streamed directly into /data/local below.
ui_print "- Extracting NetHunter module payload"
"$KSU_BUSYBOX" unzip -oq "$ORIGINAL_ZIP" -d "$MODPATH" \
    -x 'kalifs-*' 'customize.sh' 'META-INF/*' || abort "Payload extraction failed"

TMP="$MODPATH"
TARGET="$MODPATH/system"
if [ -d /system/xbin ]; then
    XBIN="$TARGET/xbin"
else
    XBIN="$TARGET/bin"
fi
mkdir -p "$XBIN"

# The official NetHunter APK invokes the literal command name "su".  KSU's
# sucompat hook handles the privilege transition, but Android 11 applications
# still need an executable at /system/bin/su for Runtime.exec() to resolve it.
# Use Android's existing shell binary only as the filesystem entry point; the
# kernel replaces the execution path through its KSU hook.
mkdir -p "$TARGET/bin"
"$KSU_BUSYBOX" cp -f /system/bin/sh "$TARGET/bin/su" \
    || abort "Unable to create the KSU sucompat entry point"
chmod 0755 "$TARGET/bin/su"
chown 0:2000 "$TARGET/bin/su" 2>/dev/null || true

# Install the Android front ends. A failed optional store component should not
# invalidate an otherwise working chroot installation.
ui_print "- Installing NetHunter applications"
install_apk "$MODPATH/data/app/NetHunter.apk" NetHunter.apk || abort "Core NetHunter app installation failed"
install_apk "$MODPATH/data/app/NetHunterTerminal.apk" NetHunterTerminal.apk || true
install_apk "$MODPATH/data/app/NetHunterKeX.apk" NetHunterKeX.apk || true
install_apk "$MODPATH/data/app/NetHunterStore.apk" NetHunterStore.apk || true
install_apk "$MODPATH/data/app/NetHunterStorePrivilegedExtension.apk" NetHunterStorePrivilegedExtension.apk || true

# Put NetHunter's BusyBox variants in the module overlay. The official
# post-fs-data.sh creates the applet links after the next boot.
ui_print "- Installing NetHunter BusyBox payload"
for BB_FILE in "$MODPATH"/tools/busybox_nh-*; do
    [ -f "$BB_FILE" ] || continue
    cp -f "$BB_FILE" "$XBIN/" || abort "BusyBox copy failed"
    chmod 0755 "$XBIN/$(basename "$BB_FILE")"
done

# Preserve the official additional /data/local payload without attempting to
# remount Android's system partition.
if [ -d "$MODPATH/data/local" ]; then
    ui_print "- Installing additional data files"
    mkdir -p /data/local
    cp -af "$MODPATH/data/local/." /data/local/ || abort "Additional data copy failed"
fi

# Stream the compressed rootfs from the verified official archive. This avoids
# storing a second 1.6 GiB kalifs archive under the KSU module directory.
KALIFS=$("$KSU_BUSYBOX" unzip -l "$ORIGINAL_ZIP" | awk '$4 ~ /^kalifs-(full|minimal|nano)-arm64\.tar\.xz$/ {print $4; exit}')
[ -n "$KALIFS" ] || abort "ARM64 Kali rootfs not found in official ZIP"

CHROOT="$NHSYS/kali-arm64"
ROOTFS="$NHSYS/kalifs"
[ ! -e "$CHROOT" ] || abort "Existing Kali chroot detected at $CHROOT"

ui_print "- Extracting Kali ARM64 rootfs"
ui_print "  This can take 10-25 minutes"
mkdir -p "$NHSYS" || abort "Unable to create $NHSYS"
"$KSU_BUSYBOX" unzip -p "$ORIGINAL_ZIP" "$KALIFS" \
    | "$KSU_BUSYBOX" tar -xJf - -C "$NHSYS" --exclude 'kali-arm64/dev' \
    || abort "Kali rootfs extraction failed"

[ -d "$CHROOT" ] || abort "Extracted Kali chroot directory is missing"
ln -sfn "$CHROOT" "$ROOTFS"
mkdir -p "$CHROOT/dev"
chmod 0755 "$NHSYS" "$CHROOT" "$CHROOT/dev"

# Apply module permissions and grant the permissions accepted by this Android
# release. Unsupported grants are intentionally non-fatal.
set_tree_perm "$TARGET" 0 0 0755 0644
set_tree_perm "$XBIN" 0 0 0755 0755
for PERM in ACCESS_BACKGROUND_LOCATION ACCESS_COARSE_LOCATION \
    ACCESS_FINE_LOCATION READ_EXTERNAL_STORAGE WRITE_EXTERNAL_STORAGE \
    WRITE_SECURE_SETTINGS; do
    pm grant com.offsec.nethunter "android.permission.$PERM" >/dev/null 2>&1 || true
done

# The KSU installer and OverlayFS metamodule finish metadata registration and
# relocate system/ after this script returns successfully.
ui_print "- Kali chroot installed at $CHROOT"
ui_print "- NetHunter KSU adaptation completed"
