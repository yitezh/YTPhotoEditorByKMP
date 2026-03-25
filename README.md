# YTPhotoEditorByKMP

一款 Lightroom 风格的跨平台图片编辑应用，基于 Kotlin Multiplatform（KMP）构建，使用 Kiro 驱动开发。从需求定义、架构设计到代码实现，整个开发流程由 Kiro 的 Spec 驱动开发工作流完成。

## 功能

### 基础调整
- **光线**：曝光、对比度、高光、阴影
- **色彩**：饱和度、自然饱和度、色温
- **细节**：锐度（iOS 端额外支持纹理、清晰度、去朦胧）

### 滤镜与效果
- 10 个内置滤镜预设（鲜艳、暖色、冷色、黑白、复古、褪色、电影感、清新、日落、胶片）

### 裁剪与变换
- 裁剪工具（支持自由、1:1、4:3、3:2、16:9 比例）
- 90° 旋转

### 其他功能
- 撤销 / 重做
- JPEG / PNG 导出，可选质量参数
- 深色主题 UI，模仿 Adobe Lightroom

## 技术栈

### 共享层（KMP）
- Kotlin 2.0.21 + Kotlin Multiplatform
- kotlinx.serialization（JSON 序列化）
- kotlinx.coroutines（异步处理）

### Android 端
- Jetpack Compose + Material 3
- Android ColorMatrix 滤镜渲染
- MediaStore 导出到相册
- MVVM 架构

### iOS 端
- Swift + UIKit
- Core Image（CIFilter 链式非破坏性编辑）
- PHPicker 选图 + Photos 框架导出
- MVVM 架构

## 由 Kiro 驱动

本项目使用 Kiro 的 Spec 驱动开发流程构建：

1. **需求阶段** — 根据功能想法生成结构化需求文档（EARS 模式 + INCOSE 质量规则）
2. **设计阶段** — 产出架构设计、组件接口、数据模型和正确性属性
3. **实现阶段** — 按任务清单逐步实现代码，每步都有对应验证

完整的 Spec 文档位于 `.kiro/specs/kmp-photo-editor/` 目录下。

## 项目结构

```
YTPhotoEditorByKMP/
├── shared/                          KMP 共享模块
│   └── src/
│       ├── commonMain/              跨平台业务逻辑
│       │   └── kotlin/.../
│       │       ├── EditParameters.kt        编辑参数模型
│       │       ├── EditHistory.kt           撤销/重做管理
│       │       ├── FilterEngineLogic.kt     滤镜引擎逻辑
│       │       ├── FilterPreset.kt          滤镜预设
│       │       ├── AdjustmentKey.kt         调整项枚举
│       │       ├── AspectRatio.kt           裁剪比例
│       │       ├── EditParametersSerializer.kt  JSON 序列化
│       │       └── Platform.kt              平台声明（expect）
│       ├── androidMain/             Android 平台实现（ImageRenderer, PhotoLibraryExporter）
│       └── iosMain/                 iOS 平台实现（Core Image 渲染, Photos 导出）
├── androidApp/                      Android 应用（Jetpack Compose）
│   └── src/main/kotlin/.../
│       ├── MainActivity.kt
│       ├── PhotoEditorViewModel.kt
│       └── ui/                      Compose UI 组件
├── iosApp/                          iOS 应用（UIKit）
│   ├── Models/                      数据模型
│   ├── ViewModels/                  视图模型
│   ├── Views/                       UI 视图
│   └── Services/                    核心服务（FilterEngine, EditHistory 等）
├── build.gradle.kts                 根构建配置
└── settings.gradle.kts              项目设置
```

## 构建与运行

### Android
使用 Android Studio 打开项目根目录，选择 `androidApp` 运行。

### iOS
1. 使用 Xcode 打开 `iosApp/PhotoEditor.xcodeproj`
2. 选择模拟器或真机，直接运行

> iOS 端目前使用原生 Swift 实现独立运行。如需启用 KMP 共享逻辑，需先执行 `./gradlew :shared:assembleXCFramework` 生成框架并集成。

## 许可证

MIT
