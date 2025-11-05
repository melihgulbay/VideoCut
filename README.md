# VideoCut - Flutter Desktop Video Editor

![Flutter](https://img.shields.io/badge/Flutter-3.35.7-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)
![Riverpod](https://img.shields.io/badge/State-Riverpod_2.6.1-00D4FF)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)

A professional desktop video editor showcasing advanced **Flutter development skills** - custom design system, Riverpod state management, and pixel-perfect UI implementation.

---

## ?? Flutter Skills Demonstrated

? **Advanced State Management** - Riverpod StateNotifier with immutable state  
? **Custom Design System** - Reusable components, consistent theming  
? **Complex UI** - Multi-track timeline, drag-drop, real-time preview  
? **FFI Integration** - Native C++ bridge for video processing  
? **Responsive Design** - Adaptive layouts, flexible sizing  
? **Clean Architecture** - Scalable, maintainable, testable code  

---

## ?? Features

- ?? Multi-track timeline with drag-and-drop
- ?? Real-time video preview with audio sync
- ? Clip trimming, splitting, speed control
- ?? Scale, rotate, position videos
- ?? Text overlays with custom styling
- ?? Modern dark theme UI
- ?? Keyboard shortcuts
- ?? Unlimited undo/redo
- ?? Multiple aspect ratios (16:9, 9:16, 1:1, etc.)
- ?? Quality presets (4K, 1080p, 720p, 480p)

---

## ??? Flutter Architecture

### Project Structure
```
lib/
??? main.dart          # App entry point
??? providers/       # Riverpod state management
?   ??? editor_provider.dart     # Main app state
??? screens/
?   ??? editor_screen.dart       # Main editing screen
??? widgets/
?   ??? toolbar.dart             # Top toolbar
?   ??? timeline_widget.dart     # Multi-track timeline
?   ??? video_preview.dart       # Video preview
? ??? properties/       # Property panels
?   ??? common/    # Reusable components
?     ??? studio_button.dart
?       ??? studio_slider.dart
?     ??? studio_card.dart
?       ??? studio_text_field.dart
?  ??? studio_switch.dart
??? theme/  # Design system
?   ??? colors.dart      # Color palette
?   ??? typography.dart          # Font system
?   ??? spacing.dart             # Spacing scale
?   ??? app_theme.dart      # Theme config
??? models/
?   ??? text_layer_data.dart     # Data models
??? audio/
?   ??? audio_playback_manager.dart
??? utils/
    ??? animations.dart          # Animation helpers
```

### State Management (Riverpod)
```dart
// Immutable state with Riverpod
class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(EditorState.initial());

  void updateClip(int clipId, {double? scaleX, double? scaleY}) {
    state = state.copyWith(
      clips: state.clips.map((clip) => 
        clip.id == clipId 
      ? clip.copyWith(scaleX: scaleX, scaleY: scaleY)
          : clip
      ).toList(),
  );
  }
}

// Consumer widget
class VideoPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return /* ... */;
  }
}
```

### Custom Design System
```dart
// Consistent component API
StudioButton.primary(
  onPressed: () => exportVideo(),
  icon: Icons.file_download,
  label: 'Export',
  size: StudioButtonSize.medium,
)

// Typography
Text('Timeline', style: AppTypography.headingMedium)

// Spacing (8px grid)
Padding(padding: EdgeInsets.all(AppSpacing.m))

// Colors
Container(color: AppColors.accentBlue)
```

---

## ?? Design System

### Color Palette
```dart
primaryBlack:     #0A0A0A  // Background
secondaryBlack:   #1A1A1A  // Cards
tertiaryBlack:    #2A2A2A// Hover

accentBlue:  #007BFF  // Primary actions
accentBlueDim:    #005BBF  // Hover

textPrimary:      #FFFFFF
textSecondary:    #B0B0B0
textTertiary:     #808080
```

### Typography
```dart
// Headings - Poppins
headingLarge:  24px, 600
headingMedium: 20px, 600

// Body - Inter
bodyLarge:     16px, 400
bodyMedium:    14px, 400

// Mono - JetBrains Mono
mono:          14px, 400
```

### Components
All components follow Material 3 principles with custom styling:

**StudioButton** - Multi-variant button system
- Primary (filled, high emphasis)
- Secondary (outlined, medium emphasis)
- Text (low emphasis)

**StudioSlider** - Themed slider with labels

**StudioCard** - Container with consistent styling

**StudioTextField** - Form input with validation

**StudioSwitch** - Toggle control

---

## ?? Tech Stack

### Frontend
- **Framework**: Flutter 3.35.7
- **Language**: Dart 3.9.2
- **State Management**: Riverpod 2.6.1
- **UI**: Material 3 with custom theme

### Key Packages
```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  file_picker: ^6.2.1
  audioplayers: ^5.2.1
  ffi: ^2.1.0
```

---

## ?? Key Features for Portfolio

### 1. Advanced State Management
- Riverpod StateNotifier pattern
- Immutable state updates
- Granular widget rebuilds
- State persistence across sessions

### 2. Custom UI Components
Fully reusable component library:
```dart
StudioButton.primary()
StudioButton.secondary()
StudioSlider(label: 'Scale', value: 1.0, ...)
StudioCard(child: /* ... */)
```

### 3. Complex Interactions
- Drag-and-drop timeline clips
- Interactive resize handles
- Real-time preview updates
- Keyboard shortcuts
- Smooth animations

### 4. Responsive Design
- Adaptive layouts for different window sizes
- Flexible widget composition
- Material 3 responsive breakpoints

### 5. Performance
- Efficient list rendering (ListView.builder)
- Debounced UI updates
- Frame caching
- Memory-efficient image handling

---

## ?? Screenshots

![Main Interface](https://via.placeholder.com/800x450?text=Multi-track+Timeline+Editor)
*Multi-track timeline with real-time preview*

![Components](https://via.placeholder.com/800x450?text=Design+System+Components)
*Reusable UI components from design system*

---

## ??? Getting Started

### Prerequisites
```bash
Flutter SDK 3.35.7+
Dart SDK 3.9.2+
```

### Installation
```bash
# Clone
git clone https://github.com/melihgulbay/VideoCut.git
cd VideoCut

# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux
```

---

## ?? What This Project Shows

**For Flutter Developers:**

? **Riverpod Mastery** - Complex state management patterns  
? **Design Systems** - Scalable, reusable component libraries  
? **Custom UI** - Beyond basic Material widgets  
? **FFI Integration** - Native code bridges  
? **Architecture** - Clean, testable, maintainable  
? **Production Ready** - Error handling, performance, UX  

**Perfect showcase for:**
- MVP/SaaS development
- Enterprise Flutter apps
- Design-to-code implementation
- Advanced UI/UX
- Cross-platform desktop apps

---

## ?? License

MIT License

---

## ????? Developer

**Melih Gülbay**

Portfolio-quality Flutter project demonstrating:
- Advanced state management
- Custom design systems
- Complex UI implementation
- Production-ready architecture

**Built for showcasing Flutter development expertise in job applications** ??

---

*Perfect for demonstrating Flutter skills to companies like WeStudio and similar development teams!*
