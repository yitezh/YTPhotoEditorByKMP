# 实现计划：KMP 照片编辑器

## 概述

将现有 iOS 照片编辑器迁移为 Kotlin Multiplatform 架构。shared 模块用纯 Kotlin 实现所有业务逻辑，iOS 端通过 XCFramework 复用现有 Swift/UIKit 代码，Android 端使用 Jetpack Compose 新建 UI。

## 任务

- [x] 1. 搭建 KMP 项目结构与 Gradle 配置
  - 在 `YTPhotoEditorByKMP/` 下创建 `settings.gradle.kts`，声明 `shared`、`androidApp` 两个模块
  - 配置 `shared/build.gradle.kts`：启用 `kotlin("multiplatform")`，添加 `iosArm64`、`iosSimulatorArm64`、`androidTarget` 目标
  - 添加依赖：`kotlinx-serialization-json`（commonMain）、`kotest-property` + `kotlin-test`（commonTest）
  - 配置 `androidApp/build.gradle.kts`：添加 Compose、ViewModel、Lifecycle 依赖
  - 创建 `shared/src/commonMain`、`commonTest`、`iosMain`、`androidMain` 目录骨架
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2. 实现 shared/commonMain 核心数据模型
  - [x] 2.1 实现 `EditParameters` data class 与 `CropRect`
    - 添加 `@Serializable` 注解，所有参数默认值为 0，`cropRect` 默认为 null，`rotationCount` 默认为 0
    - 实现 `isDefault` 计算属性
    - _Requirements: 3.2, 5.7, 9.1_

  - [ ]* 2.2 为 `EditParameters` 编写属性测试（Property 1）
    - **Property 1: EditParameters 默认值不变量**
    - **Validates: Requirements 3.2**

  - [x] 2.3 实现 `AdjustmentKey` 枚举与 `ToolTab` 枚举
    - 定义 8 个调整键，实现 `tabGroup` 映射（LIGHT / COLOR / DETAIL）
    - _Requirements: 3.1, 8.5_

  - [x] 2.4 实现 `AspectRatio` 枚举
    - 定义 FREE、SQUARE、FOUR_THREE、THREE_TWO、SIXTEEN_NINE 五个值及对应 `ratio: Float?`
    - _Requirements: 5.2_

  - [x] 2.5 实现 `FilterPreset` data class
    - 添加 `@Serializable` 注解，字段：`id`、`name`、`parameters: EditParameters`
    - _Requirements: 4.1_


- [x] 3. 实现 `EditHistory`
  - [x] 3.1 实现 `EditHistory` 类（undo/redo 双栈）
    - 实现 `push`、`undo`、`redo`、`clear` 方法及 `canUndo`、`canRedo` 属性
    - undo 后 push 新参数时清除 redo 栈
    - _Requirements: 6.1, 6.2, 6.3, 6.8_

  - [ ]* 3.2 为 `EditHistory` 编写属性测试（Property 2）
    - **Property 2: push 增长不变量**
    - **Validates: Requirements 3.6, 6.1**

  - [ ]* 3.3 为 `EditHistory` 编写属性测试（Property 3）
    - **Property 3: undo-redo round-trip**
    - **Validates: Requirements 6.2, 6.3**

  - [ ]* 3.4 为 `EditHistory` 编写属性测试（Property 4）
    - **Property 4: undo 后 push 清除 redo 历史**
    - **Validates: Requirements 6.8**

  - [ ]* 3.5 为 `EditHistory` 编写单元测试
    - 测试空历史时 `undo`/`redo` 返回 null
    - 测试 `canUndo`/`canRedo` 初始为 false
    - _Requirements: 6.4, 6.5, 6.6, 6.7_

- [x] 4. 实现 `FilterEngineLogic` 与内置预设
  - [x] 4.1 实现 `RenderParams` data class 与 `FilterEngineLogic`
    - 实现 `applyPreset`、`removePreset`、`mapToRenderParams` 方法
    - _Requirements: 4.4, 4.6_

  - [x] 4.2 定义至少 10 个内置 `FilterPreset`（鲜艳、暖色、冷色、黑白、复古、褪色、电影感、清新、日落、胶片）
    - 在 `FilterEngineLogic.builtinPresets` 中初始化
    - _Requirements: 4.1_

  - [ ]* 4.3 为 `FilterEngineLogic` 编写属性测试（Property 5）
    - **Property 5: 滤镜应用同步参数**
    - **Validates: Requirements 4.4**

  - [ ]* 4.4 为 `FilterEngineLogic` 编写属性测试（Property 6）
    - **Property 6: 滤镜应用-移除 round-trip**
    - **Validates: Requirements 4.6**

  - [ ]* 4.5 为 `FilterEngineLogic` 编写单元测试
    - 验证内置预设数量 ≥ 10
    - 验证具体预设（如"黑白"）的参数值符合预期
    - _Requirements: 4.1_

- [x] 5. 实现裁剪与旋转逻辑
  - [x] 5.1 在 `FilterEngineLogic` 中实现宽高比约束计算函数
    - 输入：`AspectRatio`、当前宽高；输出：约束后的 `CropRect`
    - _Requirements: 5.3_

  - [x] 5.2 实现旋转计数更新函数（mod 4 语义）
    - 在 `EditParameters` 或工具函数中实现 `rotate()` → `rotationCount = (rotationCount + 1) % 4`
    - _Requirements: 5.4, 5.7_

  - [ ]* 5.3 为宽高比约束编写属性测试（Property 7）
    - **Property 7: 宽高比约束正确性**
    - **Validates: Requirements 5.3**

  - [ ]* 5.4 为旋转编写属性测试（Property 8）
    - **Property 8: 旋转 round-trip（4 次回到原值）**
    - **Validates: Requirements 5.4**

  - [ ]* 5.5 为裁剪取消编写属性测试（Property 9）
    - **Property 9: 裁剪取消恢复状态**
    - **Validates: Requirements 5.6**


- [x] 6. 实现 `EditParametersSerializer` 与 `PrettyPrinter`
  - [x] 6.1 实现 `EditParametersSerializer` object
    - 使用 `kotlinx.serialization` 实现 `serialize`、`deserialize`（返回 `Result<EditParameters>`）、`prettyPrint`
    - 无效 JSON 时返回 `Result.failure`，不抛出未处理异常
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [ ]* 6.2 为序列化编写属性测试（Property 10）
    - **Property 10: EditParameters 序列化 round-trip**
    - **Validates: Requirements 9.1, 9.2, 9.3**

  - [ ]* 6.3 为 `PrettyPrinter` 编写属性测试（Property 11）
    - **Property 11: PrettyPrinter 输出包含所有字段**
    - **Validates: Requirements 9.4**

  - [ ]* 6.4 为序列化编写单元测试（边界与错误场景）
    - 测试无效 JSON 字符串返回 `Result.failure`
    - 测试缺少必要字段时返回 `Result.failure`
    - _Requirements: 9.5_

- [x] 7. Checkpoint — 确保所有 commonTest 测试通过
  - 确保所有测试通过，如有问题请向用户提问。

- [x] 8. 实现 shared/iosMain actual 实现
  - [x] 8.1 实现 `PlatformImage` actual（UIImage/CIImage wrapper）
    - _Requirements: 1.2_

  - [x] 8.2 实现 `ImageRenderer` actual（Core Image 滤镜链）
    - 将 `RenderParams` 映射到 `CIFilter` 参数，实现 `renderPreview` 和 `renderFullResolution`
    - _Requirements: 2.7, 7.1_

  - [x] 8.3 实现 `PhotoLibraryExporter` actual（Photos framework）
    - 支持 JPEG（含质量参数）和 PNG 导出，写入相册，返回 `Result<Unit>`
    - _Requirements: 7.2, 7.3, 7.6, 7.7_

- [x] 9. 实现 shared/androidMain actual 实现
  - [x] 9.1 实现 `PlatformImage` actual（Android Bitmap wrapper）
    - _Requirements: 1.2, 11.4_

  - [x] 9.2 实现 `ImageRenderer` actual（Bitmap API）
    - 将 `RenderParams` 映射到 `ColorMatrix` / `BitmapFactory` 操作，实现预览与全分辨率渲染
    - _Requirements: 2.7, 7.1, 11.4_

  - [x] 9.3 实现 `PhotoLibraryExporter` actual（MediaStore API）
    - 支持 JPEG/PNG 导出，通过 `MediaStore.Images` 写入相册，返回 `Result<Unit>`
    - _Requirements: 7.2, 7.3, 7.6, 7.7, 11.5_

- [x] 10. 实现 iOS 端集成（Swift/UIKit 复用）
  - [x] 10.1 配置 Xcode 工程引入 KMP 生成的 XCFramework
    - 在 `iosApp/` 下配置 Xcode 项目，添加 shared XCFramework 依赖
    - _Requirements: 10.1_

  - [x] 10.2 在 `PhotoEditorViewController` 中注入 KMP shared 实例
    - 替换现有业务逻辑调用为 `EditHistory`、`FilterEngineLogic`、`EditParametersSerializer` 的 KMP 实例
    - 保留所有现有 Swift/UIKit 视图层代码不变
    - _Requirements: 10.1, 10.3_

  - [x] 10.3 实现参数变化回调机制（KMP → Swift）
    - 通过闭包或 delegate 将 `EditParameters` 变化通知 `PhotoEditorViewController`，触发 UI 更新
    - 如存在命名冲突，在 shared 中添加 `@ObjCName` 注解
    - _Requirements: 10.2, 10.4_

  - [x] 10.4 连接 iOS 撤销/重做按钮状态到 `EditHistory.canUndo`/`canRedo`
    - _Requirements: 6.4, 6.6_


- [x] 11. 实现 Android `PhotoEditorViewModel`
  - [x] 11.1 创建 `PhotoEditorViewModel`，持有 shared 模块实例
    - 初始化 `EditHistory`、`FilterEngineLogic`、`ImageRenderer`、`PhotoLibraryExporter`
    - 定义 `PhotoEditorUiState` data class
    - _Requirements: 11.2_

  - [x] 11.2 实现 `uiState: StateFlow<PhotoEditorUiState>`
    - 将 `EditParameters` 变化通过 `StateFlow` 暴露给 Compose UI
    - _Requirements: 11.3_

  - [x] 11.3 实现 ViewModel 操作方法
    - `updateParameter`、`applyPreset`、`removePreset`、`applyCrop`、`undo`、`redo`、`exportPhoto`
    - _Requirements: 3.4, 4.4, 4.6, 5.5, 6.1, 6.2, 6.3, 7.1_

  - [x] 11.4 实现照片加载逻辑（从相册选择 → Bitmap → PlatformImage）
    - 加载中设置 `isLoading = true`，失败时设置 `error` 字段
    - _Requirements: 2.2, 2.4, 2.6_

- [x] 12. 实现 Android Compose UI 组件
  - [x] 12.1 实现 `ImagePreviewArea` Composable
    - 显示预览图，加载时显示 `CircularProgressIndicator`，错误时显示错误信息与重试按钮
    - 深色背景 `#1A1A1A`，保持图片宽高比
    - _Requirements: 2.2, 2.4, 2.6, 8.2, 8.4_

  - [x] 12.2 实现 `FilterPresetRow` Composable
    - 水平可滚动列表，每项显示缩略图与名称，点击触发 `applyPreset`/`removePreset`
    - _Requirements: 4.2, 4.3, 4.4, 4.6_

  - [x] 12.3 实现 `ToolTabBar` Composable
    - 显示"光效 / 颜色 / 效果 / 细节"四个标签，切换时水平滑动动画
    - 使用 Material Icons
    - _Requirements: 8.2, 8.5, 8.7, 8.9_

  - [x] 12.4 实现 `AdjustmentPanel` Composable
    - 按当前 tab 显示对应滑块列表，每个滑块显示当前数值，双击重置为 0
    - 滑块变化时调用 `updateParameter`
    - _Requirements: 3.1, 3.3, 3.4, 3.5_

  - [x] 12.5 实现 `CropOverlay` Composable
    - 显示可调整大小的裁剪框，支持宽高比选择，确认/取消按钮
    - _Requirements: 5.1, 5.2, 5.3, 5.6_

  - [x] 12.6 实现 `PhotoEditorScreen` 顶层 Composable，组合所有子组件
    - 连接撤销/重做按钮到 `canUndo`/`canRedo` 状态，禁用逻辑
    - 导出按钮触发 `exportPhoto`，导出中显示进度指示器
    - _Requirements: 6.5, 6.7, 7.4, 7.5, 8.2, 8.4_

- [ ] 13. Checkpoint — 确保所有测试通过，Android 编译无错误
  - 确保所有测试通过，如有问题请向用户提问。

- [ ] 14. 端到端连线与集成验证
  - [ ] 14.1 验证 Android 完整编辑流程（加载 → 调整 → 滤镜 → 裁剪 → 撤销/重做 → 导出）
    - 编写 `PhotoEditorViewModel` 集成测试（JUnit4 + Robolectric），覆盖主要状态流转
    - _Requirements: 2.2, 3.4, 4.4, 5.5, 6.2, 7.1_

  - [ ] 14.2 验证 iOS XCFramework 集成（编译 + 基本调用链）
    - 编写 XCTest 测试 `ImageRenderer` actual 的 Core Image 参数映射
    - _Requirements: 10.1, 10.2_

- [ ] 15. Final Checkpoint — 确保所有测试通过
  - 确保所有测试通过，如有问题请向用户提问。

## 备注

- 标有 `*` 的子任务为可选项，可跳过以加快 MVP 进度
- 每个任务均引用具体需求条款以保证可追溯性
- Property 测试使用 `kotest-property`，在 `shared/src/commonTest` 中实现，每个属性至少运行 100 次迭代
- 单元测试与属性测试互补：属性测试覆盖通用不变量，单元测试聚焦具体示例与边界条件
- iOS 端保留现有 Swift/UIKit 视图层，仅将业务逻辑委托给 KMP shared 模块
