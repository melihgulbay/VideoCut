# VideoCut - Complete AI Assistant Guide

**Last Updated**: 2025-01-23  
**Version**: 1.0  
**Project Location**: `C:\VideoCut\`

---

## ?? Quick Start (Read This First!)

VideoCut is a **desktop video editor** built with **Flutter (UI) + C++ (video processing core) + FFmpeg**.

### Architecture Overview
```
???????????????????????????????????????????????????????????
?  Flutter UI (Dart)            ?
?  • Riverpod state management              ?
?  • Material 3 design with custom dark theme    ?
?  • Real-time preview rendering    ?
???????????????????????????????????????????????????????????
   ? FFI (dart:ffi)
???????????????????????????????????????????????????????????
?  C++ Core (native/)        ?
?  • Timeline: Manages clips, tracks, text layers       ?
?  • VideoEngine: FFmpeg-based video decoding             ?
?  • AudioEngine: Audio extraction & waveforms   ?
?  • Exporter: Video encoding (H.264/AAC)    ?
?  • Renderer: Frame compositing with scaling/blending    ?
???????????????????????????????????????????????????????????
```

### Key Technologies
- **Frontend**: Flutter 3.35.7, Riverpod 2.6.1
- **Backend**: C++17, CMake 3.29.3
- **Video**: FFmpeg (shared libs in `/ffmpeg/`)
- **Build**: Visual Studio 2022, Ninja
- **Platform**: Windows (primary), potential Mac/Linux

---

## ?? Project Structure

```
C:\VideoCut\
??? lib/     # Flutter/Dart code
?   ??? main.dart         # App entry point
?   ??? providers/       # Riverpod state management
?   ?   ??? editor_provider.dart  # MAIN STATE - EditorState + notifier
?   ??? screens/
?   ?   ??? editor_screen.dart    # Main editing screen
?   ??? widgets/
?   ?   ??? toolbar.dart          # Top toolbar (import/export/playback)
?   ?   ??? timeline_widget.dart  # Timeline with tracks/clips
?   ?   ??? video_preview.dart    # Video preview canvas
?   ?   ??? properties/  # Clip/text properties panels
?   ?   ??? common/       # Reusable UI components
?   ??? theme/             # App theme (colors, typography, spacing)
?   ??? audio/     # Audio playback manager
?   ??? export/            # Export dialog & wrapper
?   ??? native/  # FFI bindings
?   ?   ??? bindings.dart   # C function signatures
?   ?   ??? video_engine_wrapper.dart  # Timeline/Clip/Track wrappers
?   ??? models/    # Data models (TextLayerData, etc.)
?
??? native/       # C++ video processing core
?   ??? CMakeLists.txt            # Build configuration
?   ??? include/
?   ?   ??? timeline.h     # Timeline class (clips, tracks, text)
?   ?   ??? video_engine.h # Video decoding
?   ?   ??? audio_engine.h        # Audio extraction
?   ?   ??? exporter.h          # Video export
?   ?   ??? renderer.h   # Frame compositing
?   ?   ??? simple_text_renderer.h # Text overlay rendering
?   ?   ??? types.h     # Shared data structures
?   ?   ??? api.h          # FFI-exposed functions
?   ??? src/
?       ??? timeline.cpp      # Main timeline logic
?       ??? video_engine.cpp      # FFmpeg video decoding
?       ??? audio_engine.cpp      # FFmpeg audio processing
?       ??? exporter.cpp          # Video encoding pipeline
?    ??? renderer.cpp          # Frame scaling/blending
?       ??? simple_text_renderer.cpp # Software text rendering
?       ??? api.cpp    # FFI wrapper functions
?
??? ffmpeg/  # FFmpeg shared libraries
?   ??? ffmpeg-master-latest-win64-gpl-shared/
?   ??? bin/*.dll         # Runtime DLLs
?       ??? lib/*.lib      # Import libraries
?    ??? include/            # FFmpeg headers
?
??? windows/        # Flutter Windows runner
??? build/             # Build output (gitignored)
??? docs/      # Documentation
??? assets/    # App resources (logo, etc.)
```

---

## ?? Core Concepts

### 1. **Timeline Structure**
```
Timeline
??? Tracks (ordered by display_order, NOT track_id)
?   ??? Text Track (display_order: 0, top)
?   ??? Video Track (display_order: 1, middle)
?   ??? Audio Track (display_order: 2, bottom)
??? For each Track:
    ??? Clips (video/audio files placed on timeline)
    ?   ??? Properties: start_time, duration, trim, speed, volume, scale
    ??? Text Layers (only on text tracks)
        ??? Properties: text, position, font, color, rotation
```

**CRITICAL**: Tracks are displayed by `display_order` (top to bottom), NOT `track_id`. Never confuse these!

### 2. **State Management (EditorState)**
Located in `lib/providers/editor_provider.dart`:
```dart
class EditorState {
  Timeline timeline;     // C++ timeline handle
  List<ClipData> clips;           // Dart mirror of C++ clips
  List<TrackData> tracks;         // Track metadata
  List<TextLayerData> textLayers; // Text overlays
  
  int currentTimeMs;// Playhead position
  bool isPlaying;      // Playback state
  double zoom;                // Timeline zoom level
  
  int? selectedClipId;     // Currently selected clip
  int? selectedTextLayerId;     // Currently selected text
  
  AspectRatioPreset aspectRatio;  // 16:9, 9:16, 1:1, etc.
  VideoQuality quality;      // 1080p, 720p, 480p, etc.
  
  int exportWidth;        // Calculated from aspect + quality
  int exportHeight;      // Calculated from aspect + quality
}
```

### 3. **FFI Memory Management**

**Who owns what:**
- **C++ allocates**: Video frames, audio buffers, timeline data
- **Dart receives**: Pointers (`Pointer<Void>` handles)
- **C++ frees**: When Dart calls `destroy()` or `release()`

**CRITICAL RULES:**
1. Always call `timeline->renderFrameAt(0, &frame)` to release frames
2. Call `exporter_destroy()` after each export (never reuse!)
3. AudioEngine/VideoEngine are short-lived (load ? use ? close)

### 4. **Video Scaling (Source-Aware)**
```cpp
// WRONG (old way - stretches video):
int scaled_width = target_width * clip->scale_x;

// CORRECT (source-aware - preserves aspect):
int scaled_width = source_video_width * clip->scale_x;
```
Video scaling is **relative to original video dimensions**, not canvas size. This ensures 9:16 videos stay 9:16, 1:1 stays 1:1, etc.

### 5. **Aspect Ratio System**
- User selects **Aspect Ratio** (16:9, 9:16, 1:1, etc.)
- User selects **Quality** (1080p, 720p, 480p)
- System calculates: `exportWidth = quality.height * aspectRatio.ratio`
- Preview renders at `exportWidth x exportHeight`
- Export uses **same dimensions** (WYSIWYG)

---

## ?? Common Tasks

### Task 1: Add a New Feature to UI
1. **Create widget**: `lib/widgets/my_feature.dart`
2. **Add to EditorState** (if needs state): `lib/providers/editor_provider.dart`
3. **Use Riverpod**: `ref.watch(editorProvider)` to read, `ref.read(editorProvider.notifier)` to modify
4. **Follow design system**: Use `AppColors`, `AppTypography`, `AppSpacing` from `lib/theme/`

### Task 2: Add Native Functionality
1. **Define struct** (if needed): `native/include/types.h`
2. **Add method**: `native/include/timeline.h` (or relevant header)
3. **Implement**: `native/src/timeline.cpp`
4. **Expose via FFI**: Add function to `native/include/api.h` and `native/src/api.cpp`
5. **Bind in Dart**: Add to `lib/native/bindings.dart`
6. **Wrap in class**: Update `lib/native/video_engine_wrapper.dart`
7. **Build**: `cmake --build native/build --config Release`
8. **Copy DLLs**: `Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\`

### Task 3: Fix a Bug
1. **Reproduce**: Understand exact steps
2. **Locate**: Check relevant provider (state) or C++ component
3. **Common gotchas**:
   - Track display order vs track ID confusion
   - FFI memory not released (causes crashes)
   - Exporter reused (must create new for each export)
   - Scale relative to wrong base (canvas vs source)
4. **Test**: `flutter run -d windows`
5. **Verify**: Test edge cases (empty timeline, single clip, gaps)

### Task 4: Export Issues
**Most common export bugs:**
1. **Crash on second export** ? Not creating new `VideoExporter()` per export
2. **Preview ? Export** ? Different render dimensions (must match `exportWidth/Height`)
3. **Stretched video** ? Scaling relative to canvas instead of source video
4. **Black gaps frozen** ? Not filling black frames on `renderFrameAt()` failure
5. **Audio out of sync** ? Audio segment extraction boundaries incorrect

---

## ?? Known Gotchas & Solutions

### 1. Turkish Characters in Path
**Problem**: Flutter's shader compiler (`impellerc.exe`) corrupts Turkish characters (ü ? Ôö£ÔòØ).  
**Solution**: Move project to ASCII-only path like `C:\VideoCut\`.

### 2. Track Order Confusion
**Problem**: UI shows tracks by `display_order`, but developers think it's by `track_id`.  
**Solution**: Always use `display_order` for rendering. It's immutable after creation.

### 3. Export Crashes After Multiple Exports
**Problem**: Reusing same `Exporter` instance causes FFmpeg context corruption.  
**Solution**: Create new `VideoExporter()` for each export, dispose after completion.

### 4. DLL Not Found
**Problem**: Native DLL built but not copied to Flutter runner directory.  
**Solution**: 
```powershell
Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\ -Force
```
Or run `fix-dlls.bat` (if it exists).

### 5. CMake Cache Issues (New PC)
**Problem**: CMake cache references old PC paths.  
**Solution**:
```powershell
Remove-Item -Recurse -Force native\build
Remove-Item -Recurse -Force build
flutter clean
cmake -S native -B native\build -G "Visual Studio 17 2022" -A x64
cmake --build native\build --config Release
```

---

## ?? Build & Run

### First Time Setup (New PC)
```powershell
# 1. Install Flutter
# Download from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\src\flutter
# Add C:\src\flutter\bin to PATH

# 2. Enable Windows Desktop
flutter config --enable-windows-desktop

# 3. Enable Developer Mode (for symlinks)
# Run: start ms-settings:developers
# Toggle "Developer Mode" ON

# 4. Get Flutter dependencies
cd C:\VideoCut
flutter pub get

# 5. Build native library
Remove-Item -Recurse -Force native\build -ErrorAction SilentlyContinue
cmake -S native -B native\build -G "Visual Studio 17 2022" -A x64
cmake --build native\build --config Release

# 6. Copy DLLs
Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\ -Force

# 7. Run app
flutter run -d windows
```

### Daily Development
```powershell
# After changing C++ code:
cmake --build native\build --config Release
Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\ -Force
flutter run -d windows  # Hot restart (R) to reload native lib

# After changing Dart code:
# Just hot reload (r) in running app

# Clean build:
flutter clean
Remove-Item -Recurse -Force native\build
# Then rebuild as above
```

---

## ?? Data Flow Examples

### Example 1: User Imports Video
```
1. User clicks Import ? FilePicker dialog
2. toolbar.dart: _importVideo() called
3. EditorProvider.addClip(filepath) called
4. FFI: timeline_add_clip() ? C++ Timeline.addClip()
5. C++ creates VideoEngine, loads video, adds to clips list
6. Dart receives clip_id
7. EditorProvider updates state.clips list
8. UI rebuilds (Riverpod notifies listeners)
9. TimelineWidget shows new clip
10. VideoPreview renders frame at currentTimeMs
```

### Example 2: User Scales Video
```
1. User drags scale slider in VideoPropertiesPanel
2. EditorProvider.setClipScale(clipId, scaleX, scaleY)
3. FFI: timeline_set_clip_scale() ? C++ Timeline.setClipScale()
4. C++ updates clip->info.scale_x, scale_y
5. Dart updates state.clips[index].scaleX/Y
6. VideoPreview re-renders frame
7. C++ Timeline.compositeFrames() applies:
   scaled_width = source_video_width * scaleX
8. Frame rendered and displayed
```

### Example 3: User Exports Video
```
1. User clicks Export ? ExportDialog shown
2. User selects output path, codec, bitrate
3. Settings returned with exportWidth/Height from EditorState
4. NEW VideoExporter() created
5. exporter.startExport(timeline, settings)
6. C++ Exporter.initializeEncoder() sets up FFmpeg encoder
7. For each frame timestamp:
   - renderFrameAt(exportWidth, exportHeight) ? RGBA frame
   - Convert RGBA ? YUV420P (sws_scale)
   - Encode frame (avcodec_send_frame)
8. Audio clips mixed and encoded (AAC)
9. Mux video + audio ? MP4
10. exporter.dispose() called ? C++ cleanup
11. Success notification shown
```

---

## ?? UI/UX Guidelines

### Design System
- **Colors**: `AppColors` (black/white/blue palette)
  - Primary: `#0A0A0A` (deep black)
  - Accent: `#007BFF` (blue)
  - Text: `#FFFFFF` (white)
- **Typography**: `AppTypography` (Inter for UI, Poppins for headings, JetBrains Mono for code)
- **Spacing**: `AppSpacing` (xs: 4, s: 8, m: 16, l: 24, xl: 32)
- **Components**: Use `StudioButton`, `StudioSlider`, `StudioTextField`, etc. from `lib/widgets/common/`

### Animation Guidelines
- Duration: 150-300ms for UI transitions
- Curve: `Curves.easeInOut` for most, `Curves.elasticOut` for playful
- Use `AppAnimations.fadeIn()`, `shimmer()` from `lib/utils/animations.dart`

---

## ?? Testing Checklist

Before marking a feature complete:
- [ ] Preview matches export (WYSIWYG)
- [ ] Works with 16:9, 9:16, 1:1 aspect ratios
- [ ] Works with 1080p, 720p, 480p qualities
- [ ] Works with empty timeline
- [ ] Works with single clip
- [ ] Works with gaps between clips
- [ ] Works with 9:16 source video (don't stretch!)
- [ ] Works with 1:1 source video (don't stretch!)
- [ ] Undo/redo works
- [ ] Multiple exports in one session (no crash!)
- [ ] No memory leaks (task manager check)
- [ ] No flickering/visual glitches

---

## ?? Debugging Tips

### Flutter DevTools
```powershell
flutter run -d windows
# Opens DevTools at http://127.0.0.1:9100
# Use: Widget Inspector, Performance, Network, Logging
```

### C++ Debugging
- Add `std::cout << "[DEBUG] message" << std::endl;` in C++ code
- Rebuild: `cmake --build native\build --config Release`
- Watch console output when running app

### Common Debug Patterns
```cpp
// Check if pointer is valid
if (!handle) {
    std::cerr << "[ERROR] Null handle!" << std::endl;
    return ErrorCode::ERROR_INVALID_PARAMETER;
}

// Log frame render
std::cout << "[RENDER] Frame at " << timestamp_ms << "ms, "
      << width << "x" << height << std::endl;

// Validate state
if (output_ctx_ != nullptr) {
    std::cerr << "[WARNING] output_ctx not cleaned up!" << std::endl;
}
```

---

## ?? Important Files Reference

### Must-Read Files
1. `lib/providers/editor_provider.dart` - **Main state management**
2. `native/src/timeline.cpp` - **Core timeline logic**
3. `native/include/types.h` - **All data structures**
4. `lib/widgets/toolbar.dart` - **Import/export flow**
5. `lib/widgets/video_preview.dart` - **Preview rendering**

### Configuration Files
- `pubspec.yaml` - Flutter dependencies
- `native/CMakeLists.txt` - C++ build config
- `windows/CMakeLists.txt` - Flutter Windows config

### Build Artifacts (Generated)
- `build/` - Flutter build output
- `native/build/` - C++ build output
- `.dart_tool/` - Dart tools cache
- `windows/flutter/ephemeral/` - Flutter engine files

---

## ?? Critical Rules (Don't Break!)

1. **NEVER reuse Exporter instances** - Create new for each export
2. **ALWAYS call renderFrameAt(0, &frame)** to release frames
3. **Track display by display_order** - NOT track_id
4. **Scale relative to source video** - NOT canvas
5. **Export dimensions = preview dimensions** - Must match exactly
6. **Create tracks before adding clips** - Timeline needs tracks first
7. **Sync text layers before export** - Call `syncTextLayersToNative()`
8. **UTF-8 paths only** - No Turkish/special characters in project path
9. **x64 build only** - FFmpeg is 64-bit
10. **Copy DLLs after build** - Native DLL must be in runner directory

---

## ?? Learning Path for New AI

**If you're a fresh AI assistant, read in this order:**

1. **Start here** - This file (AI_ASSISTANT_GUIDE.md)
2. **Quick ref** - `docs/QUICK_REFERENCE.md` (5 min overview)
3. **Architecture** - `docs/ARCHITECTURE.md` (system design)
4. **Based on task:**
   - Backend work ? `docs/BACKEND_GUIDE.md`
   - Frontend work ? `docs/FRONTEND_GUIDE.md`
   - Algorithm details ? `docs/ALGORITHMS.md`
   - UI styling ? `docs/DESIGN_SYSTEM.md`

**Time estimates:**
- Quick task: This file only (~10 min)
- Backend task: This + BACKEND_GUIDE (~20 min)
- Frontend task: This + FRONTEND_GUIDE (~20 min)
- Full understanding: All docs (~45 min)

---

## ?? Emergency Fixes

### App Won't Build
```powershell
flutter clean
Remove-Item -Recurse -Force native\build
Remove-Item -Recurse -Force build
flutter pub get
cmake -S native -B native\build -G "Visual Studio 17 2022" -A x64
cmake --build native\build --config Release
Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\ -Force
flutter run -d windows
```

### App Crashes on Export
```dart
// In toolbar.dart _exportVideo():
final exporter = VideoExporter(); // Create NEW
final started = await exporter.startExport(...);
// ... show progress dialog ...
exporter.dispose(); // ALWAYS dispose after
```

### Preview/Export Don't Match
```dart
// In exporter.cpp:
rs.width = output_width;   // Must match export dimensions
rs.height = output_height; // NOT hardcoded 1920x1080!
```

### Video Stretched Wrong
```cpp
// In timeline.cpp compositeFrames():
// Use SOURCE dimensions, not target:
int scaled_width = clip_frame.width * clip->info.scale_x;
int scaled_height = clip_frame.height * clip->info.scale_y;
```

---

## ?? Quick Reference Card

| Need | Command/Path |
|------|-------------|
| Run app | `flutter run -d windows` |
| Build C++ | `cmake --build native\build --config Release` |
| Copy DLLs | `Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\` |
| Clean all | `flutter clean; Remove-Item -Recurse native\build` |
| State management | `lib/providers/editor_provider.dart` |
| Timeline logic | `native/src/timeline.cpp` |
| FFI bindings | `lib/native/bindings.dart` |
| Export flow | `lib/widgets/toolbar.dart` ? `_exportVideo()` |
| Theme colors | `lib/theme/colors.dart` |
| Data structures | `native/include/types.h` |

---

## ?? Success Metrics

A working VideoCut app should:
- ? Import video/audio files
- ? Display clips on timeline
- ? Play preview with audio sync
- ? Split, trim, delete clips
- ? Adjust speed, volume, scale
- ? Add text overlays
- ? Change aspect ratio (16:9, 9:16, 1:1, etc.)
- ? Export to MP4 (H.264/AAC)
- ? Match preview in export (WYSIWYG)
- ? Handle multiple exports without crash
- ? Support undo/redo
- ? Render at 30fps in preview

---

**Good luck! You've got this. ??**

*P.S. If something's not clear, check the detailed docs in `/docs/` or examine the source code. The codebase is well-structured and comments explain tricky parts.*
