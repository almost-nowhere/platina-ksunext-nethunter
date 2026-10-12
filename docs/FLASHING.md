# 刷入、安装和回滚

## 刷入前

1. 确认机型：`adb shell getprop ro.product.device` 必须输出 `platina`。
2. 备份当前 boot 镜像与重要数据。
3. 确保 bootloader 已解锁，并保留可用的 recovery 或 fastboot。
4. 验证发布文件：

   ```sh
   sha256sum -c SHA256SUMS
   ```

## 刷入 boot

优先使用已确认适用于本机 ROM 的 recovery 刷入 boot 镜像；或在 fastboot 中执行：

```sh
fastboot flash boot boot-platina-lineage18.1-KSUNext-33189-NetHunter-OverlayFS-Permissive-KSUFix.img
fastboot reboot
```

不要对未知设备、未知 slot 布局或未验证的 ROM 盲目执行上述命令。

## 安装 NetHunter

1. 启动系统并在 KernelSU Next Manager 确认 root 可用。
2. 从 Kali 官方下载 Generic ARM64 Full 2026.2 ZIP，保存为：

   ```text
   /sdcard/Download/kali-nethunter-2026.2-generic-arm64-full.zip
   ```

3. 在 KernelSU Next Manager 安装 `NetHunter-2026.2-generic-arm64-full-KSU-adapter-platina-r2.zip`。
4. 重启系统。首次 rootfs 展开需要较长时间与至少约 12 GiB 的 `/data` 空间。
5. 卸载官方 NetHunter 主应用，再安装 `NetHunter-2026.2-zh-rCN-final.apk`。不要卸载 NetHunter Terminal 或 KeX，除非你也要更换它们。
6. 打开 NetHunter，并在 KernelSU Next Manager 中允许 root 权限。

## 回滚

刷回你自己的原始 boot 镜像即可回到原内核。若要移除 Kali：在 KernelSU Next Manager 中禁用/卸载 adapter 模块，并手动确认后删除 `/data/local/nhsystem/kali-arm64`。删除 rootfs 是不可恢复操作。
