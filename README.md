# CLX S20P 自定义固件（ImmortalWrt 25.12）

目标设备：**CLX S20P / MediaTek MT7986 / `mediatek/filogic` / `clx,s20p`**。

本工程使用 `chasey-dev/immortalwrt-mt798x-rebase` 的 `25.12` 分支，并读取
`Jameslau-tech/ActionsOpenWrtMT798X` 的 S20P 原始配置。编译脚本以原始设备配置为基础，
清理额外 LuCI 插件，但保留 MTK 专有驱动和设备功能配置。

## 应集成的应用

- OpenClash
- Diskman
- ttyd（含 LuCI 管理界面）
- Samba4（含 LuCI 管理界面；不同时启用 ksmbd）
- 挂载点和常见磁盘文件系统支持

此外保留设备维护所需的基础管理界面：防火墙、MTK Wi-Fi 配置、MTK TurboACC 管理。
这些是设备/系统管理功能，不属于额外安装的第三方应用。

## S20P 关键配置保护

`verify-packages.sh` 在 `make defconfig` 后检查以下项目仍然启用：

- `clx_s20p` 设备 profile
- `kmod-mt_wifi` 和 `CONFIG_MTK_MT_WIFI_DRIVER_VERSION_7673`（MTK Wi-Fi 7.6.7.3）
- `kmod-mediatek_hnat`
- `kmod-warp` 和 `CONFIG_MTK_WARP_V2`
- MTK Wi-Fi 与 TurboACC 管理界面

如果这些项目被 Kconfig 自动取消，工作流会失败，不会把该配置标记为成功。

## 挂载点说明

挂载功能使用 OpenWrt/ImmortalWrt 的 `block-mount`、`automount` 和 LuCI 系统挂载点管理页面，
通常位于 **系统 → 挂载点**。Diskman 另提供磁盘/分区管理功能。
本工程不假定一定存在独立的 `luci-app-mount` 包；不会因该包不存在而伪造安装成功。

## 如何上传并编译

1. 解压本工程 ZIP。
2. 打开自己的 GitHub 仓库，选择 **Add file → Upload files**。
3. 上传解压后目录中的全部内容，注意 `.github/workflows/build-s20p.yml` 必须保留在这个准确路径。
4. 点击 **Commit changes**。
5. 打开仓库的 **Actions**，选择 **Build CLX S20P**。
6. 点击 **Run workflow → Run workflow**。
7. 等待工作流完成。成功后打开该次运行页面，在 **Artifacts** 下载 `S20P-firmware`。

如果 GitHub 网页上传时没有显示 `.github` 目录，不能只上传 README 和 scripts；必须确保 workflow 文件实际进入 `.github/workflows/`，否则 Actions 中不会出现本工程的编译任务。

## 重要注意事项

- 首次构建需要从上游下载完整源码和依赖，耗时较长；GitHub Actions 可能因资源、上游变化或包依赖问题失败。
- OpenClash 集成 LuCI 应用及其构建依赖，不包含你的订阅、节点或个性化规则；首次启动后自行配置。
- Samba4 首次启动后仍需配置共享目录、账户和权限。不要把 SMB 或 ttyd 直接暴露到公网。
- ttyd 是 Web 终端，只建议在可信 LAN 中使用。
- 刷机前确认设备确实是 CLX S20P，备份现有配置。不要刷入其他机型固件。
- 本工程尚未完成 GitHub Actions 实际编译，也未在真实 S20P 上验证启动、无线覆盖、吞吐量、HNAT/WARP 行为。**编译通过不等于实机验证通过。**
