# YTPhotoEditorByKMP

一款 Lightroom 风格的跨平台图片编辑应用，基于 Kotlin Multiplatform（KMP）构建，使用 Kiro 驱动开发。Android 和 iOS 共享核心业务逻辑，UI 层各端原生实现。

## 功能

### 基础调整
- **光线**：曝光、对比度、高光、阴影
- **色彩**：饱和度、自然饱和度、色温
- **细节**：锐度、纹理、清晰度、去朦胧

### 滤镜与效果
- 10 个内置滤镜预设（鲜艳、暖色、冷色、黑白、复古、褪色、电影感、清新、日落、胶片）

### 裁剪与变换
- 裁剪工具（支持自由、1:1、4:3、3:2、16:9 比例）
- 90° 旋转

### 其他功能
- 撤销 / 重做（KMP 共享逻辑）
- JPEG / PNG 导出，可选质量参数
- 深色主题 UI，模仿 Adobe Lightroom

## KMP 共享架构

### 共享层提供（shared 模块，双端复用）
- `EditParameters` — 编辑参数数据模型
- `EditHistory` — 撤销/重做栈管理
- `FilterEngineLogic` — 滤镜预设管理、参数应用与移除
- `FilterPreset` — 滤镜预设定义及 10 个内置预设
- `EditParametersSerializer` — JSON 序列化/反序列化
- `AdjustmentKey` / `ToolTab` / `AspectRatio` — 枚举定义

### 各端原生实现
- **Android**：Jetpack Compose UI + ColorMatrix 渲染
- **iOS**：UIKit 视图层 + Core Image（CIFilter）渲染 + Photos 框架导出

### iOS 端桥接层
- `KMPBridge` — KMP Kotlin 类型与 Swift 类型的双向转换
- `KMPPhotoEditorViewModel` — 通过 Bridge 委托业务逻辑给 KMP，驱动 UIKit 视图

## 技术栈

### 共享层（KMP）
- Kotlin 2.0.21 + Kotlin Multiplatform
- kotlinx.serialization（JSON 序列化）
- kotlinx.coroutines（异步处理）

### Android 端
- Jetpack Compose + Material 3
- MVVM 架构

### iOS 端
- Swift + UIKit
- Core Image（CIFilter 链式非破坏性编辑）
- PHPicker + Photos 框架
- MVVM 架构（KMP 驱动）

## 由 Kiro 驱动

本项目使用 Kiro 的 Spec 驱动开发流程构建：

1. **需求阶段** — 生成结构化需求文档
2. **设计阶段** — 产出架构设计、组件接口、数据模型
3. **实现阶段** — 按任务清单逐步实现代码

完整的 Spec 文档位于 `.kiro/specs/kmp-photo-editor/` 目录下。

## 项目结构

```
YTPhotoEditorByKMP/
├── shared/                          KMP 共享模块
│   └── src/
│       ├── commonMain/              跨平台业务逻辑（双端共享）
│       │   └── EditParameters, EditHistory, FilterEngineLogic,
│       │       FilterPreset, AdjustmentKey, AspectRatio,
│       │       EditParametersSerializer, Platform(expect)
│       ├── androidMain/             Android 平台实现（ImageRenderer, Exporter）
│       └── iosMain/                 iOS 平台实现（ImageRenderer, Exporter）
├── androidApp/                      Android 应用（Jetpack Compose）
│   └── ui/                          Compose UI 组件
├── iosApp/                          iOS 应用（UIKit）
│   ├── KMPBridge.swift              KMP ↔ Swift 类型桥接
│   ├── KMPPhotoEditorViewModel.swift  KMP 驱动的 ViewModel
│   ├── Models/                      UI 层值类型定义
│   ├── Views/                       UIKit 视图
│   └── Services/                    FilterEngine, ExportManager, PhotoLoader
└── gradle/                          Gradle 配置
```

## 构建与运行

### Android
使用 Android Studio 打开项目根目录，选择 `androidApp` 运行。

### iOS
1. 确保已安装 JDK 17：`brew install openjdk@17`
2. 使用 Xcode 打开 `iosApp/PhotoEditor.xcodeproj`
3. 选择模拟器或真机，直接运行（Xcode 会自动通过 Gradle 构建 shared framework）

## 许可证

MIT
