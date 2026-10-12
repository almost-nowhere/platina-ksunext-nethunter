# NetHunter 2026.2 KernelSU adapter for platina

This small module is an adapter for the unmodified official file:

`/sdcard/Download/kali-nethunter-2026.2-generic-arm64-full.zip`

It verifies the official SHA-256, installs the Android applications, streams
the ARM64 Kali rootfs into `/data/local/nhsystem`, and leaves `system/` content
for KernelSU's OverlayFS MetaModule. It does not install or flash a kernel.

