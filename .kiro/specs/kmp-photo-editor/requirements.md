# 需求文档

## 简介

本项目将现有 iOS 照片编辑器（YTPhotoEditorByAI）迁移为 Kotlin Multiplatform（KMP）架构，工程名为 YTPhotoEditorByKMP。目标是在保留现有 iOS 功能完整性的前提下，通过 KMP 共享模块统一管理业务逻辑（编辑参数、历史管理、滤镜引擎逻辑、序列化等），iOS 端复用现有 Swift/UIKit 代码（通过 KMP 的 iOS actual 实现），Android 端使用 Jetpack Compose 实现相同的 UI 功能。

## 术语表

- **Shared_Module**: KMP 共享模块，包含平台无关的业务逻辑，编译为 iOS framework 和 Android library
- **Edit_Parameters**: 编辑参数数据模型，包含所有调整参数的当前值，定义在 Shared_Module 中
- **Filter_Engine**: 滤镜引擎接口，定义在 Shared_Module 中，负责参数计算、滤镜预设管理和序列化；平台侧负责实际图像渲染
- **Edit_History**: 编辑历史管理器，定义并实现在 Shared_Module 中，负责撤销/重做操作的记录和回放
- **Export_Manager**: 导出管理器接口，定义在 Shared_Module 中，平台侧实现实际图像编码和相册写入
- **Photo_Editor_iOS**: iOS 平台的编辑器主界面，基于现有 Swift/UIKit 代码，通过 KMP iOS actual 与 Shared_Module 集成
- **Photo_Editor_Android**: Android 平台的编辑器主界面，使用 Jetpack Compose 实现，与 Shared_Module 集成
- **Adjustment_Panel**: 调整面板，包含曝光、对比度、高光、阴影、饱和度等滑块控件，在两个平台上提供相同的功能
- **Crop_Tool**: 裁剪工具，支持自由裁剪和固定比例裁剪
- **Pretty_Printer**: 将 Edit_Parameters 格式化为人类可读 JSON 的组件，实现在 Shared_Module 中

## 需求

### 需求 1：KMP 架构分层

**用户故事：** 作为开发者，我希望业务逻辑集中在 KMP 共享模块中，以便 iOS 和 Android 共享同一套核心逻辑，减少重复代码。

#### 验收标准

1. THE Shared_Module SHALL 包含 Edit_Parameters 数据模型、Edit_History、Filter_Engine 接口及其纯逻辑实现、编辑参数序列化/反序列化
2. THE Shared_Module SHALL 通过 expect/actual 机制声明平台相关能力（图像渲染、相册访问、文件 I/O）
3. WHEN Shared_Module 被编译为 iOS XCFramework 时，THE Shared_Module SHALL 暴露与现有 Swift 代码兼容的 Objective-C 接口
4. WHEN Shared_Module 被编译为 Android AAR 时，THE Shared_Module SHALL 暴露标准 Kotlin API 供 Jetpack Compose 层调用
5. THE Shared_Module SHALL 不包含任何 UIKit、SwiftUI、Android View 或 Compose 的直接依赖

### 需求 2：图片加载与预览

**用户故事：** 作为用户，我希望将照片加载到编辑器中并看到实时预览，以便在导出前评估编辑效果。

#### 验收标准

1. WHEN 用户从相册中选择一张照片，THE Photo_Editor_iOS SHALL 在中央预览区域以正确的宽高比显示该照片
2. WHEN 用户从相册中选择一张照片，THE Photo_Editor_Android SHALL 在中央预览区域以正确的宽高比显示该照片
3. WHEN 照片正在加载时，THE Photo_Editor_iOS SHALL 显示加载指示器直到照片准备就绪
4. WHEN 照片正在加载时，THE Photo_Editor_Android SHALL 显示加载指示器直到照片准备就绪
5. IF 选择的照片加载失败，THEN THE Photo_Editor_iOS SHALL 显示错误信息并允许用户重试或选择其他照片
6. IF 选择的照片加载失败，THEN THE Photo_Editor_Android SHALL 显示错误信息并允许用户重试或选择其他照片
7. WHEN 调整参数发生变化，THE Filter_Engine SHALL 在 100ms 内为不超过 1200 万像素的照片生成更新后的预览

### 需求 3：基础调整参数

**用户故事：** 作为用户，我希望通过滑块调整曝光、对比度、饱和度等参数，以便精细调整照片的外观。

#### 验收标准

1. THE Adjustment_Panel SHALL 提供以下参数的滑块：曝光、对比度、高光、阴影、饱和度、自然饱和度、色温、锐度
2. THE Edit_Parameters SHALL 将每个调整参数的范围定义为 -100 到 +100，默认值为 0
3. WHEN 用户移动滑块，THE Adjustment_Panel SHALL 在滑块旁显示当前数值
4. WHEN 用户移动滑块，THE Filter_Engine SHALL 实时将对应的调整应用到预览图上
5. WHEN 用户双击滑块，THE Adjustment_Panel SHALL 将该滑块重置为默认值 0
6. WHEN Edit_Parameters 中任意参数值发生变化，THE Edit_History SHALL 将该变化记录为一条新的历史条目

### 需求 4：滤镜预设

**用户故事：** 作为用户，我希望对照片应用预设滤镜，以便无需手动调整即可快速获得想要的效果。

#### 验收标准

1. THE Filter_Engine SHALL 在 Shared_Module 中定义至少 10 个内置滤镜预设，涵盖鲜艳、暖色、冷色、黑白、复古等风格
2. THE Photo_Editor_iOS SHALL 提供一个水平可滚动的滤镜预设列表，带有缩略图预览
3. THE Photo_Editor_Android SHALL 提供一个水平可滚动的滤镜预设列表，带有缩略图预览
4. WHEN 用户点击一个滤镜预设，THE Filter_Engine SHALL 将该滤镜的参数集合并到当前 Edit_Parameters 中
5. WHEN 滤镜预设被应用后，THE Adjustment_Panel SHALL 更新所有滑块值以反映该滤镜的参数值
6. WHEN 用户再次点击当前已激活的滤镜预设，THE Filter_Engine SHALL 移除该滤镜并恢复之前的手动调整值

### 需求 5：裁剪与旋转

**用户故事：** 作为用户，我希望裁剪和旋转照片，以便调整构图和方向。

#### 验收标准

1. WHEN 用户进入裁剪模式，THE Crop_Tool SHALL 在照片上显示一个可调整大小的裁剪框
2. THE Crop_Tool SHALL 支持以下预设宽高比：自由、1:1、4:3、3:2、16:9
3. WHEN 用户选择一个预设宽高比，THE Crop_Tool SHALL 将裁剪框约束为该比例
4. WHEN 用户点击旋转按钮，THE Crop_Tool SHALL 将照片顺时针旋转 90 度
5. WHEN 用户确认裁剪，THE Filter_Engine SHALL 将裁剪参数写入 Edit_Parameters 并更新预览
6. IF 用户取消裁剪操作，THEN THE Crop_Tool SHALL 丢弃所有裁剪和旋转更改并恢复之前的状态
7. THE Edit_Parameters SHALL 在 Shared_Module 中存储裁剪区域（x、y、width、height）和旋转角度

### 需求 6：撤销与重做

**用户故事：** 作为用户，我希望撤销和重做编辑操作，以便自由尝试而不担心丢失之前的状态。

#### 验收标准

1. WHEN 用户执行一次编辑操作，THE Edit_History SHALL 将该操作对应的 Edit_Parameters 快照记录为一条新的历史条目
2. WHEN 用户点击撤销按钮，THE Edit_History SHALL 将 Edit_Parameters 恢复到上一个快照状态
3. WHEN 用户点击重做按钮，THE Edit_History SHALL 将 Edit_Parameters 恢复到最近一次被撤销的快照状态
4. WHILE 没有执行过任何编辑操作，THE Photo_Editor_iOS SHALL 禁用撤销按钮
5. WHILE 没有执行过任何编辑操作，THE Photo_Editor_Android SHALL 禁用撤销按钮
6. WHILE 没有被撤销的操作，THE Photo_Editor_iOS SHALL 禁用重做按钮
7. WHILE 没有被撤销的操作，THE Photo_Editor_Android SHALL 禁用重做按钮
8. WHEN 用户在撤销后执行新的编辑操作，THE Edit_History SHALL 丢弃当前状态之后的所有重做历史

### 需求 7：导出

**用户故事：** 作为用户，我希望以高质量导出编辑后的照片，以便保存或分享结果。

#### 验收标准

1. WHEN 用户点击导出按钮，THE Export_Manager SHALL 渲染应用了所有调整的全分辨率编辑照片
2. THE Export_Manager SHALL 支持 JPEG 和 PNG 格式导出
3. WHEN 以 JPEG 格式导出时，THE Export_Manager SHALL 允许用户选择 1 到 100 的质量值，默认为 90
4. WHEN 导出正在进行中，THE Photo_Editor_iOS SHALL 显示进度指示器
5. WHEN 导出正在进行中，THE Photo_Editor_Android SHALL 显示进度指示器
6. WHEN 导出成功完成，THE Export_Manager SHALL 将照片保存到用户的相册并显示成功确认
7. IF 导出失败，THEN THE Export_Manager SHALL 返回包含失败原因的错误信息，由平台层展示给用户

### 需求 8：Lightroom 风格深色主题 UI

**用户故事：** 作为用户，我希望在 iOS 和 Android 上都拥有类似 Lightroom 的深色主题编辑界面，以便专注于照片而不被 UI 干扰。

#### 验收标准

1. THE Photo_Editor_iOS SHALL 使用深色主题，近黑色背景（#1A1A1A）和浅色文字（#E0E0E0）
2. THE Photo_Editor_Android SHALL 使用深色主题，近黑色背景（#1A1A1A）和浅色文字（#E0E0E0）
3. THE Photo_Editor_iOS SHALL 在屏幕上方显示照片预览，下方显示编辑工具
4. THE Photo_Editor_Android SHALL 在屏幕上方显示照片预览，下方显示编辑工具
5. THE Adjustment_Panel SHALL 将编辑工具组织为标签组：光效、颜色、效果、细节，在两个平台上保持一致
6. THE Photo_Editor_iOS SHALL 所有工具图标使用 SF Symbols
7. THE Photo_Editor_Android SHALL 所有工具图标使用 Material Icons
8. WHEN 切换工具标签时，THE Photo_Editor_iOS SHALL 以平滑的水平滑动动画过渡
9. WHEN 切换工具标签时，THE Photo_Editor_Android SHALL 以平滑的水平滑动动画过渡

### 需求 9：编辑参数序列化

**用户故事：** 作为开发者，我希望在 Shared_Module 中序列化和反序列化编辑参数，以便编辑状态可以跨平台保存和恢复。

#### 验收标准

1. THE Filter_Engine SHALL 将所有当前 Edit_Parameters 序列化为 JSON 表示
2. WHEN 提供有效的 JSON 编辑参数字符串，THE Filter_Engine SHALL 将其反序列化为等效的 Edit_Parameters 对象
3. FOR ALL 有效的 Edit_Parameters 对象，序列化后再反序列化 SHALL 产生等效的参数集（round-trip 属性）
4. THE Pretty_Printer SHALL 将 Edit_Parameters 格式化为人类可读的 JSON 输出
5. IF 提供的 JSON 字符串格式无效或缺少必要字段，THEN THE Filter_Engine SHALL 返回描述性错误而非抛出未处理异常

### 需求 10：iOS 平台集成（复用现有代码）

**用户故事：** 作为 iOS 开发者，我希望现有的 Swift/UIKit 代码通过 KMP iOS actual 实现与共享模块集成，以便最大化代码复用并避免重写。

#### 验收标准

1. THE Photo_Editor_iOS SHALL 通过 KMP 生成的 XCFramework 调用 Shared_Module 中的 Edit_History 和 Filter_Engine 逻辑
2. WHEN Shared_Module 中的 Edit_Parameters 发生变化，THE Photo_Editor_iOS SHALL 通过回调或观察者机制接收通知并更新 UI
3. THE Photo_Editor_iOS SHALL 保留现有 Swift/UIKit 视图层代码，仅将业务逻辑委托给 Shared_Module
4. IF Shared_Module 的 API 与现有 Swift 代码存在命名冲突，THEN THE Shared_Module SHALL 通过 @ObjCName 注解提供兼容的 Objective-C 名称

### 需求 11：Android 平台实现（Jetpack Compose）

**用户故事：** 作为 Android 开发者，我希望使用 Jetpack Compose 实现与 iOS 功能完全一致的编辑界面，以便 Android 用户获得同等的编辑体验。

#### 验收标准

1. THE Photo_Editor_Android SHALL 使用 Jetpack Compose 实现所有 UI 组件，包括预览区域、调整面板、滤镜列表和裁剪工具
2. THE Photo_Editor_Android SHALL 通过 ViewModel 持有 Shared_Module 中的 Edit_History 和 Filter_Engine 实例
3. WHEN Shared_Module 中的 Edit_Parameters 发生变化，THE Photo_Editor_Android SHALL 通过 StateFlow 或等效的响应式机制更新 Compose UI
4. THE Photo_Editor_Android SHALL 使用 Android 平台的 Bitmap API 实现 Filter_Engine 的 actual 图像渲染
5. THE Photo_Editor_Android SHALL 使用 MediaStore API 实现 Export_Manager 的 actual 相册写入
