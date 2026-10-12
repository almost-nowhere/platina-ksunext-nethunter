# Mi 8 Lite (platina): KSU Next + NetHunter + 中文 NetHunter

面向 Xiaomi Mi 8 Lite (`platina`) 与 LineageOS 18.1 / Android 11 的个人构建发布。

本仓库提供可刷入 boot 镜像、KernelSU Next 适配的 Generic ARM64 NetHunter 安装模块、简体中文 NetHunter 主应用，以及全部本次改动的可审查补丁和配置。

## 重要警告

- 仅适用于 `platina`。刷入其他机型可能无法启动。
- 先备份当前 boot 分区，并确保已能进入 recovery / fastboot。
- boot 镜像默认 **SELinux Permissive**，安全性显著下降，不应作为存放敏感数据的日常系统。
- 内置 Wi-Fi 的 monitor/injection 能力受高通闭源固件限制；外接兼容 USB Wi-Fi 适配器更可靠。
- 仅在已获授权的设备和网络上使用安全测试工具。

## 发布文件

| 文件 | 用途 |
| --- | --- |
| `releases/boot-platina-lineage18.1-KSUNext-33189-NetHunter-OverlayFS-Permissive-KSUFix.img` | 含 KSU Next、OverlayFS 和 NetHunter 内核配置的可刷 boot 镜像 |
| `releases/NetHunter-2026.2-generic-arm64-full-KSU-adapter-platina-r2.zip` | 将 Kali 官方 Generic ARM64 Full 载荷适配至 KernelSU Next 的模块 |
| `releases/NetHunter-2026.2-zh-rCN-final.apk` | 简体中文 NetHunter 主应用（自行签名） |
| `SHA256SUMS` | 上述发布文件的 SHA-256 校验值 |

## 快速安装

完整步骤见 [刷入说明](docs/FLASHING.md)。概要如下：

1. 校验下载文件：`sha256sum -c SHA256SUMS`。
2. 用 recovery 或 fastboot 刷入本仓库 boot 镜像；先确认设备是 `platina` 且有原始 boot 备份。
3. 安装 KernelSU Next Manager，并确认 root 正常。
4. 下载 Kali 官方 `kali-nethunter-2026.2-generic-arm64-full.zip` 到 `/sdcard/Download/`，再在 KernelSU 安装 adapter ZIP。
5. 安装中文 APK。它与官方 NetHunter 使用同一包名但签名不同，因此须先卸载官方 **NetHunter 主应用**；不会删除 `/data/local/nhsystem` 下的 Kali rootfs。
6. 在 KernelSU Next Manager 中允许 `com.offsec.nethunter` 的 root 请求。

## 已验证内容

- Android 11 / LineageOS 18.1 能启动。
- KernelSU Next root 与 MetaOverlayFS 可用。
- Kali 2026.2 ARM64 chroot 能以 root 进入，能看到当前内核、`/proc`、`/sys`、USB ConfigFS 与 `wlan0`。
- 中文 NetHunter 主应用在 `zh-CN` 系统语言下加载中文资源。

## 源码、补丁和许可证

上游源码：

- Kernel: <https://github.com/LineageOS/android_kernel_xiaomi_sdm660/tree/lineage-18.1>，基线 commit `2e69f2ae550dcfbde1ffb6daa11492762b122191`。
- KernelSU Next: <https://github.com/KernelSU-Next/KernelSU-Next>，基线 commit `fd093e8b879063aeb0192a3959b0652101ded623`。
- NetHunter app: <https://gitlab.com/kalilinux/nethunter/apps/kali-nethunter-app>，基线 commit `b66d050d479345ddac4e4a4b63381c7f262299ba`。

本仓库的 `patches/` 含所有本次源代码变动；`config/` 含 NetHunter 内核配置片段；`nethunter-app/` 含中文 Android 资源。内核与 KernelSU Next 的许可证副本位于 `licenses/`。

## 已知问题

- Android 11 的 VINTF 会因 `CONFIG_SYSVIPC=y` 产生 vendor interface 警告；该选项为 Kali 兼容性保留。
- NetHunter 原始应用的部分工具名、命令、参数、协议名及工具输出保留英文，避免改变实际执行内容。
- 第一次启动时 Android 可能要求定位/存储权限。

## 免责声明

这是无担保的个人构建。刷机和安全测试风险由使用者自行承担。
