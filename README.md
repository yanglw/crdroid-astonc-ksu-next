# crDroid 16.0 (Android 16) Kernel Builder for OnePlus Ace 3 / 12R

基于 GitHub Actions 的一加 Ace 3 / 一加 12R (`astonc` / `aston`) crDroid 16.0 (Android 16, Linux 5.15) 内核自动化云端构建工作流，原生支持集成 **KernelSU**、**KernelSU-Next** 与 **AnyKernel3** 卡刷包打包。

---

## 📱 适用机型与环境

- **适用设备**: 一加 Ace 3 (OnePlus Ace 3, `astonc`) / 一加 12R (OnePlus 12R, `aston`)
- **硬件平台**: 高通骁龙 8 Gen 2 (Snapdragon 8 Gen 2 / SM8550 / Kalama)
- **操作系统**: crDroid 16.0 (基于 Android 16)
- **内核基准**: Linux 5.15.x GKI (Generic Kernel Image)
- **编译工具链**: AOSP Clang r563880c (LLVM 21.0.0 Native Build)

---

## 🌟 项目核心特性

1. **底包配置 100% 动态逆向对齐**
   - 自动从输入的底包 `boot.img` 二进制中检索并解压嵌入的 `IKCONFIG` 核心配置；
   - 自动检测并写入底包真实的 `.scmversion`，保证内核 `vermagic` 与系统 `/vendor_dlkm` 预装外置驱动模块 ABI CRC 1:1 完美契合。

2. **原生 Full LTO + CFI + BTF 完整支持**
   - 完整继承官方的 **`CONFIG_LTO_CLANG_FULL=y`**（全程序链路优化）与 **`CONFIG_CFI_CLANG=y`** 控制流完整性检查；
   - 完整保留 **`CONFIG_DEBUG_INFO_BTF=y`**（BPF 类型格式），保障 Android 16 底层 `bpfloader` 正确加载，杜绝开机第一秒闪退重启；
   - 宿主机辅助工具通过原生 GCC 编译，完美兼容 BTF 与 `libelf` 符号处理。

3. **18 组专有硬件驱动完整链接**
   - 自动检出配套的 `android_kernel_oneplus_sm8550-modules`，完整映射 18 组 OPlus 专有硬件驱动：
     - 触控系统（`oplus_touchscreen_v2`、Synaptics HBP、触控固件更新）；
     - 三段式物理按键（`tri_state_key`）；
     - 屏下指纹（`uff_fp_drivers`）与安全驱动（`oplus_secure`）；
     - 线性马达（`aw8697_haptic`）与呼吸灯（`aw210xx`）；
     - 长寿版闪充协议（`power/oplus`）；
     - 红外遥控（`oplus_consumer_ir`）、NFC 与传感器总线接口。

4. **Matrix 并行构建矩阵**
   - 支持一键同时并发编译所有 3 种主流规格（约 10~12 分钟出齐全部版本）：
     - **KernelSU-Next**: 集成最新 Next 分支，支持新版特性与拓展模块；
     - **KernelSU**: 集成官方主分支，成熟稳定；
     - **Pure Stock**: 原生纯净未 Root 内核，用于对照测试与一键无损救砖。

5. **双格式产物自动封装与校验**
   - 自动打包为 **Fastboot 线刷镜像 (`.img`)** 与 **AnyKernel3 卡刷包 (`-AK3.zip`)**；
   - 自动为所有编译产物计算输出 `sha256.txt` 校验清单。

---

## 📦 最终打包产物说明

一次构建（选择 `All`）将发布以下文件：

| 文件名称 | 类型 | 适用场景 | 说明 |
| :--- | :---: | :---: | :--- |
| `crdroid-...-ksu-next-....img` | Boot 镜像 | Fastboot 线刷 | 包含 KernelSU-Next 钩子 |
| `crdroid-...-ksu-next-...-AK3.zip` | 刷机包 | Recovery 卡刷 | AnyKernel3 格式，安全保留系统引导配置 |
| `crdroid-...-ksu-....img` | Boot 镜像 | Fastboot 线刷 | 包含 KernelSU 官方主分支钩子 |
| `crdroid-...-ksu-...-AK3.zip` | 刷机包 | Recovery 卡刷 | AnyKernel3 格式 |
| `crdroid-...-stock-....img` | Boot 镜像 | Fastboot 线刷 | 纯净原厂未 Root 内核（用于一键卸载 Root / 救砖） |
| `crdroid-...-stock-...-AK3.zip` | 刷机包 | Recovery 卡刷 | 纯净原厂未 Root 内核 |
| `sha256.txt` | 文本清单 | 本地校验 | 包含以上所有产物的 SHA-256 哈希值 |

---

## 🚀 使用方法

### 1. 触发 GitHub Actions 构建

1. Fork 本仓库到你的 GitHub 账号；
2. 进入仓库的 **Actions** 标签页，点击左侧的 **Build crDroid 16.0 Boot (KernelSU / KernelSU-Next)**；
3. 点击右侧 **Run workflow**，填入参数：
   - **`Direct download URL for stock boot.img`**: 填入你当前正在使用的 crDroid 16.0 官方原版 `boot.img` 直链下载地址（支持各大 CDN 与 SourceForge 页面链接）；
   - **`Root Solution`**: 默认选择 **`All`**（同时输出所有 3 种方案），也可按需单选；
   - **`Kernel Commit SHA`**: 可选，留空将自动从 `boot.img` 中智能提取与对齐。
4. 点击 **Run workflow** 开始构建，约 10 分钟后在仓库右侧的 **Releases** 页面下载所需产物。

---

## 📲 刷入教程（任选其一）

> [!IMPORTANT]
> 刷入前请确保电脑已配置最新版 [Platform Tools (ADB & Fastboot)](https://developer.android.com/tools/releases/platform-tools)。

### 方案 A：Recovery 卡刷 / Sideload（强烈推荐 🌟）

此方案使用 AnyKernel3 在手机端原地解包并注入内核，100% 绕过 fastboot AVB 签名及分区头校验问题，安全便捷。

1. 手机关机后长按 **【音量减 + 电源键】** 进入 crDroid Recovery 模式；
2. 在 Recovery 界面中选择 **Apply update** $\rightarrow$ **Apply from ADB**；
3. 使用 USB 数据线连接电脑，在电脑终端执行：
   ```bash
   adb sideload crdroid-16.0-astonc-5.15.xxx-xxxx-ksu-next-xxxx-AK3.zip
   ```
4. 终端提示 `Total xfer: 1.00x` 完成后，在手机界面点击 **Reboot system now** 重启即可！

---

### 方案 B：Fastboot 线刷 boot.img

1. 手机进入 Bootloader / Fastboot 模式（关机状态长按 **【音量加 + 音量减 + 电源键】** 或在开机状态执行 `adb reboot bootloader`）；
2. 检查并确保当前插槽启动重试次数正常：
   ```bash
   # 查看当前生效槽位 (假设为 b)
   fastboot getvar current-slot
   
   # 若此前无限重启导致重试次数耗尽，可重置当前活动槽位：
   fastboot --set-active=b
   ```
3. 刷入对应镜像：
   ```bash
   fastboot flash boot crdroid-16.0-astonc-5.15.xxx-xxxx-ksu-next-xxxx.img
   fastboot reboot
   ```

---

## ❓ 常见问题排查（FAQ）

### Q1: 刷入后若遇到一加 Logo 重启循环怎么办？
高通平台在连续 7 次启动失败后会将该槽位的 `slot-retry-count` 标记为 0 锁死。
- **解决方式**:
  1. 长按电源键与音量键强制进入 Fastboot 模式；
  2. 执行 `fastboot --set-active=b`（切换回当前槽位重置计数）；
  3. 执行 `fastboot flash boot crdroid-...-stock-...img` 刷入纯净 Stock 内核，即可立刻秒级救砖恢复正常开机。

### Q2: 如何无损卸载 Root 权限？
只需在 Recovery 下 Sideload 刷入对应的 **`-stock-*-AK3.zip`**，即可无损去除所有 Root 钩子，恢复 100% 原生纯净状态，用户数据不受任何影响。

### Q3: 为什么构建必须保留 `CONFIG_DEBUG_INFO_BTF`？
crDroid 16.0 基于 Android 16。Android 14+ 严格依赖内核导出的 `/sys/kernel/btf/vmlinux` 运行 `bpfloader`。如果禁用了 BTF，系统在刚挂载 system 目录后就会触发 `reboot_on_failure reboot,bpfloader-failed` 导致无限重启。本项目已确保 BTF 符号 100% 完整保留。

---

## 📜 鸣谢与开源项目

- [crDroid Android](https://crdroid.net/)
- [KernelSU](https://github.com/tiann/KernelSU)
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [AnyKernel3 by osm0sis](https://github.com/osm0sis/AnyKernel3)
- [Magisk by topjohnwu](https://github.com/topjohnwu/Magisk)
