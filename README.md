# VideoCut - Professional Desktop Video Editor

![Flutter](https://img.shields.io/badge/Flutter-3.35.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)
![Riverpod](https://img.shields.io/badge/State-Riverpod_2.6.1-00D4FF)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

A production-ready, cross-platform desktop video editor built with **Flutter** and **C++**, showcasing enterprise-level architecture, advanced state management, and pixel-perfect UI implementation.

---

## ?? Why This Project Stands Out

### **Advanced Flutter Architecture**
- ? **Riverpod State Management** - StateNotifier pattern with immutable state
- ? **Clean Architecture** - Separated business logic, UI, and native integration
- ? **FFI Integration** - Custom Flutter-to-C++ bridge for video processing
- ? **Scalable Design** - Modular components, reusable widgets, testable code

### **Design System Excellence**
- ?? **Custom Theme System** - Cohesive color palette, typography, spacing
- ?? **Reusable Components** - StudioButton, StudioSlider, StudioCard, etc.
- ?? **Responsive Layouts** - Adaptive sizing for different window dimensions
- ?? **Smooth Animations** - Fade, shimmer, scale transitions

### **Production-Ready Code Quality**
- ?? **Comprehensive Documentation** - 7 detailed guides in `/docs/`
- ?? **Error Handling** - Proper exception management across FFI boundary
- ?? **Performance Optimized** - Efficient rendering, memory management
- ?? **Best Practices** - Follow Flutter/Dart conventions, DRY principles

---

## ?? Features

### Video Editing
- ?? Multi-track timeline with drag-and-drop
- ?? Real-time video preview with audio sync
- ? Clip trimming, splitting, speed control
- ?? Scale, rotate, position videos with precision
- ?? Text overlays with custom fonts and colors

### User Experience
- ?? Modern, cinematic dark theme
- ?? Keyboard shortcuts for efficiency
- ?? Unlimited undo/redo
- ?? Snap-to-grid timeline alignment
- ?? Interactive resize handles with aspect lock

### Technical Excellence
- ??? Multiple aspect ratios (16:9, 9:16, 1:1, 4:3, 21:9)
- ?? Quality presets (4K, 1080p, 720p, 480p)
- ?? Audio waveform visualization
- ?? Export to MP4 (H.264/AAC)
- ?? WYSIWYG (preview matches export exactly)

---

## ??? Architecture

### Project Structure
```
lib/
??? main.dart     # App entry point
??? providers/            # Riverpod state management
?   ??? editor_provider.dart     # Main app state & business logic
??? screens/
?   ??? editor_screen.dart       # Main editing interface
??? widgets/
?   ??? toolbar.dart      # Top toolbar (import/export/playback)
?   ??? timeline_widget.dart     # Multi-track timeline
?   ??? video_preview.dart       # Real-time preview canvas
?   ??? properties/ # Property panels (video, text)
?   ??? common/              # Reusable UI components
? ??? studio_button.dart   # Custom button system
?       ??? studio_slider.dart   # Themed sliders
?       ??? studio_card.dart     # Container component
?       ??? studio_text_field.dart
??? theme/       # Design system
?   ??? colors.dart  # Color palette
?   ??? typography.dart          # Font system
?   ??? spacing.dart      # Spacing scale
?   ??? app_theme.dart           # Theme configuration
??? models/    # Data models
?   ??? text_layer_data.dart
??? audio/          # Audio playback
?   ??? audio_playback_manager.dart
??? export/  # Export functionality
?   ??? export_dialog.dart
?   ??? export_wrapper.dart
??? native/            # FFI bindings
?   ??? bindings.dart            # C function signatures
?   ??? video_engine_wrapper.dart # Dart wrappers
??? utils/
    ??? animations.dart          # Animation utilities
```

### State Management Pattern
```dart
// Riverpod StateNotifier with immutable state
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState.initial());

  void updateClip(int clipId, {double? scaleX, double? scaleY}) {
    // Immutable state updates
    state = state.copyWith(
      clips: state.clips.map((clip) => 
     clip.id == clipId 
          ? clip.copyWith(scaleX: scaleX, scaleY: scaleY)
          : clip
      ).toList(),
    );
    
    // Sync to native layer
    _timeline.setClipScale(clipId, scaleX ?? 1.0, scaleY ?? 1.0);
  }
}

// Consumer widget pattern
class VideoPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return CustomPaint(
      painter: VideoPainter(frame: editorState.currentFrame),
    );
  }
}
```

### Design System Implementation
```dart
// Consistent theming across app
StudioButton.primary(
  onPressed: () => exportVideo(),
  icon: Icons.file_download,
  label: 'Export',
  size: StudioButtonSize.medium,
)

// Typography system
Text('Timeline', style: AppTypography.headingMedium)

// Spacing system (8px grid)
Padding(padding: EdgeInsets.all(AppSpacing.m))

// Color system
Container(color: AppColors.accentBlue)
```

---

## ?? Design System

### Color Palette
```dart
// Primary colors
primaryBlack:     #0A0A0A  // Deep black background
secondaryBlack:   #1A1A1A  // Card backgrounds
tertiaryBlack:    #2A2A2A  // Hover states

// Accent
accentBlue:       #007BFF  // Primary actions
accentBlueDim: #005BBF  // Hover states

// Text
textPrimary:   #FFFFFF  // Primary text
textSecondary:    #B0B0B0  // Secondary text
textTertiary:     #808080  // Disabled text
```

### Typography
```dart
// Headings - Poppins (bold, modern)
headingLarge:  24px, 600 weight
headingMedium: 20px, 600 weight
headingSmall:  16px, 600 weight

// Body - Inter (readable, professional)
bodyLarge:     16px, 400 weight
bodyMedium:  14px, 400 weight
bodySmall:     12px, 400 weight

// Mono - JetBrains Mono (code, timestamps)
mono: 14px, 400 weight
```

### Spacing System (8px Grid)
```dart
xs: 4px   // Tight spacing
s:  8px   // Small gaps
m:  16px  // Standard spacing
l:  24px  // Section spacing
xl: 32px  // Large spacing
xxl: 48px // Hero spacing
```

---

## ?? Getting Started

### Prerequisites
- Flutter 3.35.7 or higher
- Dart 3.9.2 or higher
- CMake 3.15+ (for native build)
- Visual Studio 2022 (Windows) or Xcode (macOS)

### Installation

```bash
# Clone repository
git clone https://github.com/melihgulbay/VideoCut.git
cd VideoCut

# Install Flutter dependencies
flutter pub get

# Build native library (Windows)
cd native
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
cd ..

# Copy native DLLs
Copy-Item native\build\Release\*.dll build\windows\x64\runner\Debug\

# Run app
flutter run -d windows
```

---

## ?? Technical Highlights

### 1. Advanced State Management
- **Riverpod** for reactive state updates
- **StateNotifier** pattern for predictable state changes
- **Provider composition** for feature isolation
- **Efficient rebuilds** with granular listeners

### 2. Custom UI Components
All components follow a consistent API pattern:

```dart
// StudioButton - Multi-variant button system
StudioButton.primary()    // Blue, high emphasis
StudioButton.secondary()  // Outlined, medium emphasis
StudioButton.text()    // Text-only, low emphasis

// StudioSlider - Themed slider with labels
StudioSlider(
  label: 'Scale',
  value: 1.0,
  min: 0.1,
  max: 3.0,
  onChanged: (v) => updateScale(v),
)

// StudioCard - Container with consistent styling
StudioCard(
  padding: AppSpacing.m,
  child: /* ... */,
)
```

### 3. FFI Integration
Seamless Dart ? C++ communication:

```dart
// Dart side
final result = timeline.renderFrameAt(
  currentTime,
  width: 1920,
  height: 1080,
);

// C++ side (native/src/api.cpp)
int timeline_render_frame_ex(
  TimelineHandle handle,
  int64_t timestamp_ms,
  FrameData* frame,
  const RenderSettings* settings
) { /* ... */ }
```

### 4. Performance Optimizations
- **Frame caching** for smooth preview playback
- **Lazy loading** of video frames
- **Debounced UI updates** during slider drag
- **Efficient list rendering** with ListView.builder
- **Memory management** across FFI boundary

---

## ?? Screenshots

### Main Editor Interface
![Main Interface](docs/screenshots/main_interface.png)
*Multi-track timeline with real-time preview and property panels*

### Design System Components
![Components](docs/screenshots/components.png)
*Reusable UI components from the design system*

### Export Dialog
![Export](docs/screenshots/export_dialog.png)
*Clean export interface with quality/aspect ratio presets*

---

## ??? Tech Stack

### Frontend
- **Framework**: Flutter 3.35.7
- **Language**: Dart 3.9.2
- **State Management**: Riverpod 2.6.1
- **UI**: Material 3 with custom theme

### Backend (Native Layer)
- **Language**: C++17
- **Video Processing**: FFmpeg
- **Build System**: CMake
- **FFI**: dart:ffi

### Tools & Libraries
- `file_picker` - File selection
- `audioplayers` - Audio playback
- `flutter_riverpod` - State management
- `ffi` - Native interop

---

## ?? Documentation

Comprehensive documentation available in `/docs/`:

- **[AI_ASSISTANT_GUIDE.md](docs/AI_ASSISTANT_GUIDE.md)** - Complete project overview
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System architecture
- **[FRONTEND_GUIDE.md](docs/FRONTEND_GUIDE.md)** - Flutter implementation details
- **[DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - UI/UX guidelines
- **[ALGORITHMS.md](docs/ALGORITHMS.md)** - Core algorithms explained

---

## ?? Key Skills Demonstrated

### For Flutter Developers
? **Advanced State Management** - Riverpod StateNotifier pattern  
? **Custom Design System** - Reusable components, consistent theming
? **Complex UI** - Multi-track timeline, interactive overlays  
? **FFI Integration** - Native C++ bridge for performance  
? **Responsive Design** - Adaptive layouts, flexible sizing  
? **Animation** - Smooth transitions, loading states  
? **Error Handling** - Proper exception management  
? **Documentation** - Well-commented, documented code  
? **Git Workflow** - Structured commits, clear history  
? **Production Ready** - Scalable, maintainable, testable  

---

## ?? Why This Project?

This project showcases:

1. **Enterprise-Level Architecture** - Scalable, maintainable codebase
2. **Design-to-Code Excellence** - Custom design system, pixel-perfect UI
3. **Advanced Flutter Features** - FFI, custom rendering, state management
4. **Production Mindset** - Documentation, error handling, performance
5. **Full-Stack Capability** - Both UI and native integration

Perfect for demonstrating **Flutter expertise** in:
- MVP/SaaS development
- Complex UI implementation
- State management mastery
- Design system creation
- Production-ready code

---

## ?? License

MIT License - See [LICENSE](LICENSE) file for details

---

## ????? Developer

**Melih Gülbay**

- GitHub: [@melihgulbay](https://github.com/melihgulbay)
- LinkedIn: [Melih Gülbay](https://linkedin.com/in/melihgulbay)
- Portfolio: [Your Portfolio URL]

---

## ?? Acknowledgments

Built as a showcase of Flutter development capabilities, demonstrating:
- Clean architecture principles
- Modern UI/UX design
- Advanced state management
- Native integration expertise
- Production-ready code quality

**Perfect for portfolio/job applications showcasing Flutter + Dart mastery!** ??

---

*Last Updated: January 2025*
