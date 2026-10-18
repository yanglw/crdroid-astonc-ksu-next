# crDroid 12.0 & 13.0 (Android 16 & 17) Kernel Builder for OnePlus Ace 3 / 12R

基于 GitHub Actions 的一加 Ace 3 / 一加 12R (`astonc` / `aston`) crDroid 内核自动化云端构建工作流。原生支持同时或单独编译 **crDroid 12.0 (Android 16)** 与 **crDroid 13.0 (Android 17)** 内核，集成 **KernelSU**、**KernelSU-Next** 与官方 **AnyKernel3 (arm64)** 自动卡刷包封装。

---

## 📱 适用机型与环境

- **适用设备**: 一加 Ace 3 (OnePlus Ace 3, `astonc`) / 一加 12R (OnePlus 12R, `aston`)
- **硬件平台**: 高通骁龙 8 Gen 2 (Snapdragon 8 Gen 2 / SM8550 / Kalama)
- **支持系统**: 
  - **crDroid 13.0** (基于 Android 17，源码分支 `17.0`)
  - **crDroid 12.0** (基于 Android 16，源码分支 `16.0`)
- **内核基准**: Linux 5.15.x GKI (Generic Kernel Image 2.0+)
- **编译工具链**: AOSP Clang r563880c (LLVM 21.0.0 Native Build)
- **CI 运行环境**: GitHub Actions (Node.js 24 原生支持, Ubuntu 22.04 LTS)

---

## 🌟 项目核心特性

1. **crDroid 12 与 13 双版本智能按需构建**
   - **输入驱动**：根据填入的 `boot_url_13` 和 `boot_url_12` 智能计算矩阵；
   - **单选/双选自由**：只填一个 URL 则仅编译对应版本；两个 URL 都填则在云端并发并行编译两个版本，互不干扰；
   - **独立 Commit 控制**：支持分别为 12 和 13 指定不同的自定义内核 Commit SHA，留空则自动从各自底包中精确提取与对齐。

2. **底包配置 100% 动态逆向对齐 (纯 Shell 算法)**
   - 自动从输入的底包 `boot.img` 二进制中检索并解压嵌入的 `IKCONFIG` 核心配置；
   - 采用标准 Linux 内核二进制偏移检索算法，完全基于 Bash 实现，杜绝 Python 依赖；
   - 自动检测并写入底包真实的 `.scmversion`，保证内核 `vermagic` 与系统 `/vendor_dlkm` 预装外置驱动模块 ABI CRC 1:1 契合。

3. **100% 纯 Bash 模块化架构**
   - 将复杂的 Action 构建管道解耦为 [`scripts/`](scripts/) 目录下的 8 个独立标准 Bash 脚本；
   - 统一使用 `set -euo pipefail` 严格错误处理，提高可维护性，支持本地与 CI 环境复现。

4. **官方 AnyKernel3 移植与纯 64 位 (arm64) 适配**
   - 脱离过时的第三方 AnyKernel3 分支，直接接入官方 [`osm0sis/AnyKernel3`](https://github.com/osm0sis/AnyKernel3)；
   - 采用官方维护的最新 **`arm64-tools`** 纯 64 位工具链，完美适配一加 Ace 3 在 Android 14/15/16/17 下无 32 位运行库的纯 64 位 Recovery 环境；
   - 适配 GKI `init_boot` 架构（`split_boot; flash_boot;`），并彻底移除会导致 ADB Sideload 卡死的音量键轮询。

5. **原生 Full LTO + CFI + BTF 完整支持**
   - 完整继承官方的 **`CONFIG_LTO_CLANG_FULL=y`**（全程序链路优化）与 **`CONFIG_CFI_CLANG=y`** 控制流完整性检查；
   - 完整保留 **`CONFIG_DEBUG_INFO_BTF=y`**（BPF 类型格式），保障 Android 底层 `bpfloader` 正常加载，杜绝开机第一秒闪退重启；
   - 动态配置 24GB Swap 交换内存，保障多线程 Full LTO 链接阶段零 OOM 内存溢出。

6. **18 组专有硬件驱动完整链接**
   - 自动检出对应分支的 `android_kernel_oneplus_sm8550-modules`，完整映射 18 组 OPlus 专有硬件驱动：
     - 触控系统（`oplus_touchscreen_v2`、Synaptics HBP、触控固件更新）；
     - 三段式物理按键（`tri_state_key`）；
     - 屏下指纹（`uff_fp_drivers`）与安全驱动（`oplus_secure`）；
     - 线性马达（`aw8697_haptic`）与呼吸灯（`aw210xx`）；
     - 长寿版闪充协议（`power/oplus`）；
     - 红外遥控（`oplus_consumer_ir`）、NFC 与传感器总线接口。

7. **Matrix 并发构建与统一聚合发布**
   - 支持并发编译所有主流 Root 规格：
     - **KernelSU-Next**: 集成最新 Next 分支，支持新版特性与拓展模块；
     - **KernelSU**: 集成官方主分支，成熟稳定；
     - **Pure Stock**: 原生纯净未 Root 内核，用于对照测试与一键无损救砖。
   - 所有构建任务完成后统一汇聚打包，自动生成 `sha256.txt` 校验清单并发布至 GitHub Releases。

---

## 📦 产物规格与命名说明

单次构建发布的文件命名格式如下：

| 产物文件名 | 类型 | 适用系统 | 说明 |
| :--- | :---: | :---: | :--- |
| `crdroid-17.0-ksu-next-boot-*.img` | Boot 镜像 | crDroid 13 (Android 17) | Fastboot 线刷，集成 KernelSU-Next |
| `crdroid-17.0-ksu-next-AnyKernel3-*.zip` | 卡刷包 | crDroid 13 (Android 17) | Recovery 模式刷入，AnyKernel3 格式 |
| `crdroid-17.0-ksu-boot-*.img` | Boot 镜像 | crDroid 13 (Android 17) | Fastboot 线刷，集成 KernelSU 官方稳定版 |
| `crdroid-17.0-ksu-AnyKernel3-*.zip` | 卡刷包 | crDroid 13 (Android 17) | Recovery 模式刷入 |
| `crdroid-17.0-stock-boot-*.img` | Boot 镜像 | crDroid 13 (Android 17) | 原生未 Root 纯净镜像（一键救砖/卸载 Root） |
| `crdroid-17.0-stock-AnyKernel3-*.zip` | 卡刷包 | crDroid 13 (Android 17) | 原生未 Root 纯净卡刷包 |
| `crdroid-16.0-ksu-next-boot-*.img` | Boot 镜像 | crDroid 12 (Android 16) | Fastboot 线刷，集成 KernelSU-Next |
| `crdroid-16.0-ksu-next-AnyKernel3-*.zip` | 卡刷包 | crDroid 12 (Android 16) | Recovery 模式刷入，AnyKernel3 格式 |
| `crdroid-16.0-ksu-boot-*.img` | Boot 镜像 | crDroid 12 (Android 16) | Fastboot 线刷，集成 KernelSU 官方稳定版 |
| `crdroid-16.0-ksu-AnyKernel3-*.zip` | 卡刷包 | crDroid 12 (Android 16) | Recovery 模式刷入 |
| `crdroid-16.0-stock-boot-*.img` | Boot 镜像 | crDroid 12 (Android 16) | 原生未 Root 纯净镜像 |
| `crdroid-16.0-stock-AnyKernel3-*.zip` | 卡刷包 | crDroid 12 (Android 16) | 原生未 Root 纯净卡刷包 |
| `sha256.txt` | 文本清单 | 全部 | 包含该次 Release 所有文件的 SHA-256 哈希值 |

---

## 🚀 使用方法

### 1. 触发 GitHub Actions 构建

1. Fork 本仓库到你的 GitHub 账号；
2. 进入仓库的 **Actions** 标签页，点击左侧的 **Build crDroid Boot (KernelSU / KernelSU-Next)**；
3. 点击右侧 **Run workflow**，填入参数：
   - **`boot_url_13`**: 填入 crDroid 13 (Android 17) 官方 `boot.img` 下载直链（不需要编译 13 则留空）；
   - **`boot_url_12`**: 填入 crDroid 12 (Android 16) 官方 `boot.img` 下载直链（不需要编译 12 则留空）；
   - **`Root Solution`**: 默认选择 **`All`**（同时输出所有 3 种方案），也可按需单选 `KernelSU-Next`、`KernelSU` 或 `None (Pure Stock)`；
   - **`custom_commit_13` / `custom_commit_12`**: 可选，留空将自动从各自底包中逆向对齐。
4. 点击 **Run workflow** 开始构建，约 10~15 分钟后在仓库右侧的 **Releases** 页面下载所需产物。

---

## 📲 刷入教程（任选其一）

> [!IMPORTANT]
> 刷入前请确保电脑已配置最新版 [Platform Tools (ADB & Fastboot)](https://developer.android.com/tools/releases/platform-tools)，且下载的刷机包版本前缀（`crdroid-16.0` 或 `crdroid-17.0`）与手机当前系统版本严格对应。

### 方案 A：Recovery 卡刷 / Sideload（强烈推荐 🌟）

AnyKernel3 在手机端原地替换内核 `Image`，自动保留原版 Ramdisk、DTB 与引导参数，安全便捷。

1. 手机关机后长按 **【音量减 + 电源键】** 进入 crDroid Recovery 模式；
2. 在 Recovery 界面中选择 **Apply update** $\rightarrow$ **Apply from ADB**；
3. 使用 USB 数据线连接电脑，在电脑终端执行：
   ```bash
   adb sideload crdroid-<版本号>-<方案>-AnyKernel3-<日期>.zip
   ```
4. 终端提示 `Total xfer: 1.00x` 完成后，在手机界面点击 **Reboot system now** 重启即可！

---

### 方案 B：Fastboot 线刷 boot.img

1. 手机进入 Bootloader / Fastboot 模式（关机状态长按 **【音量加 + 音量减 + 电源键】** 或在开机状态执行 `adb reboot bootloader`）；
2. 检查并确保当前插槽启动重试次数正常：
   ```bash
   # 查看当前生效槽位 (假设为 a)
   fastboot getvar current-slot
   
   # 若此前无限重启导致重试次数耗尽，可重置当前活动槽位：
   fastboot --set-active=a
   ```
3. 刷入对应镜像：
   ```bash
   fastboot flash boot crdroid-<版本号>-<方案>-boot-<日期>.img
   fastboot reboot
   ```

---

## ❓ 常见问题排查（FAQ）

### Q1: 刷入后若遇到一加 Logo 重启循环怎么办？
高通平台在连续启动失败后会将该槽位的 `slot-retry-count` 标记为 0 锁死。
- **解决方式**:
  1. 长按电源键与音量减强制进入 Fastboot 模式；
  2. 执行 `fastboot --set-active=<当前槽位>` 重置计数；
  3. 执行 `fastboot flash boot crdroid-...-stock-...img` 刷入纯净 Stock 内核，即可立刻秒级救砖恢复正常开机。

### Q2: 如何无损卸载 Root 权限？
只需在 Recovery 下 Sideload 刷入对应版本的 **`-stock-*-AK3.zip`**，即可无损去除所有 Root 钩子，恢复 100% 原生纯净状态，用户数据不受任何影响。

### Q3: 为什么构建必须保留 `CONFIG_DEBUG_INFO_BTF`？
Android 14+ 严格依赖内核导出的 `/sys/kernel/btf/vmlinux` 运行 `bpfloader`。如果禁用了 BTF，系统在刚挂载 system 目录后就会触发 `reboot_on_failure reboot,bpfloader-failed` 导致无限重启。本项目已确保 BTF 符号 100% 完整保留。

---

## 📜 鸣谢与开源项目

- [crDroid Android](https://crdroid.net/)
- [KernelSU](https://github.com/tiann/KernelSU)
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [AnyKernel3 by osm0sis](https://github.com/osm0sis/AnyKernel3)
- [Magisk by topjohnwu](https://github.com/topjohnwu/Magisk)
