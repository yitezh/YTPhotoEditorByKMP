# iOS App Integration

This directory contains the iOS app that integrates the KMP shared module via XCFramework.

## Setup

1. Build the XCFramework from the shared module:
   ```
   ./gradlew :shared:assembleXCFramework
   ```
   This generates `shared/build/XCFrameworks/release/shared.xcframework`

2. Open `iosApp/iosApp.xcodeproj` in Xcode
3. Add the generated XCFramework to the project:
   - Drag `shared.xcframework` into the Xcode project
   - Add it to "Frameworks, Libraries, and Embedded Content"

## Architecture

The iOS app reuses all existing Swift/UIKit view code from the original app.
Business logic is delegated to the KMP shared module:
- `EditHistory` — undo/redo management
- `FilterEngineLogic` — filter preset management and parameter calculation
- `EditParametersSerializer` — JSON serialization
- `ImageRenderer` (iosMain actual) — Core Image rendering
- `PhotoLibraryExporter` (iosMain actual) — Photos framework export
