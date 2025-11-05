# VideoCut - Flutter Desktop Video Editor

A professional desktop video editor built with Flutter, showcasing advanced state management, custom design systems, and complex UI implementation.

## Flutter Implementation Overview

This project demonstrates production-level Flutter development with Riverpod state management, a complete custom design system, and sophisticated UI patterns suitable for enterprise applications.

## Technical Stack

- **Flutter**: 3.35.7
- **Dart**: 3.9.2
- **State Management**: Riverpod 2.6.1
- **Architecture**: Clean architecture with separated concerns
- **Platform**: Desktop (Windows, macOS, Linux)

## Key Flutter Features

### 1. State Management with Riverpod

The application uses Riverpod's StateNotifier pattern for predictable state updates:

```dart
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
```

Consumer widgets automatically rebuild when state changes:

```dart
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

### 2. Custom Design System

Complete component library with consistent theming:

```dart
// Buttons
StudioButton.primary(
  onPressed: () => exportVideo(),
  icon: Icons.file_download,
  label: 'Export',
  size: StudioButtonSize.medium,
)

// Typography
Text('Timeline', style: AppTypography.headingMedium)

// Spacing
Padding(padding: EdgeInsets.all(AppSpacing.m))

// Colors
Container(color: AppColors.accentBlue)
```

### 3. Project Structure

```
lib/
|-- main.dart
|-- providers/
|   `-- editor_provider.dart      # Riverpod state management
|-- screens/
|   `-- editor_screen.dart          # Main editor interface
|-- widgets/
|   |-- toolbar.dart        # Top action bar
|   |-- timeline_widget.dart        # Multi-track timeline
|   |-- video_preview.dart          # Real-time preview
|   |-- properties/     # Property panels
|   `-- common/   # Reusable components
|       |-- studio_button.dart
|       |-- studio_slider.dart
|       |-- studio_card.dart
|  |-- studio_text_field.dart
|`-- studio_switch.dart
|-- theme/
|   |-- colors.dart    # Color palette
|   |-- typography.dart             # Font system
|   |-- spacing.dart # Spacing scale
|   `-- app_theme.dart              # Theme configuration
|-- models/
|   `-- text_layer_data.dart        # Data models
|-- audio/
|   `-- audio_playback_manager.dart # Audio handling
`-- utils/
    `-- animations.dart             # Animation utilities
```

## Design System

### Color Palette

```dart
// Background colors
primaryBlack:   #0A0A0A
secondaryBlack:   #1A1A1A
tertiaryBlack:    #2A2A2A

// Accent colors
accentBlue:       #007BFF
accentBlueDim:    #005BBF

// Text colors
textPrimary:      #FFFFFF
textSecondary:    #B0B0B0
textTertiary:     #808080
```

### Typography System

```dart
// Headings - Poppins (600 weight)
headingLarge:     24px
headingMedium:    20px
headingSmall:     16px

// Body - Inter (400 weight)
bodyLarge:        16px
bodyMedium:       14px
bodySmall:        12px

// Monospace - JetBrains Mono (400 weight)
mono:      14px
```

### Spacing Scale

```dart
xs:  4px    // Tight spacing
s:   8px    // Small gaps
m:   16px   // Standard spacing
l:   24px   // Section spacing
xl:  32px   // Large spacing
xxl: 48px   // Hero spacing
```

## Component Library

### StudioButton

Multi-variant button system following Material 3 principles:

```dart
StudioButton.primary()     // Filled button, high emphasis
StudioButton.secondary()   // Outlined button, medium emphasis
StudioButton.text()        // Text-only button, low emphasis
```

### StudioSlider

Custom styled slider with labels and value display:

```dart
StudioSlider(
  label: 'Scale',
  value: 1.0,
  min: 0.1,
  max: 3.0,
  onChanged: (value) => updateScale(value),
)
```

### StudioCard

Consistent container styling:

```dart
StudioCard(
  padding: AppSpacing.m,
  child: Column(children: [...]),
)
```

## Advanced Flutter Patterns

### 1. Immutable State Updates

All state changes follow immutable patterns:

```dart
state = state.copyWith(
  selectedClipId: newId,
  clips: updatedClipsList,
);
```

### 2. Provider Composition

Modular provider architecture for feature isolation:

```dart
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(...);
final timelineProvider = Provider((ref) => ref.watch(editorProvider).timeline);
```

### 3. Custom Rendering

Custom painters for specialized UI elements:

```dart
CustomPaint(
  painter: TimelineGridPainter(zoom: editorState.zoom),
  child: Stack(children: [...]),
)
```

### 4. Efficient List Rendering

ListView.builder for performance:

```dart
ListView.builder(
  itemCount: clips.length,
  itemBuilder: (context, index) => ClipWidget(clip: clips[index]),
)
```

### 5. Debounced UI Updates

Preventing excessive rebuilds during slider interaction:

```dart
Timer? _debounceTimer;
void onSliderChanged(double value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 100), () {
    updateValue(value);
  });
}
```

## Flutter Dependencies

```yaml
dependencies:
  flutter:
  sdk: flutter
  flutter_riverpod: ^2.6.1
  file_picker: ^6.2.1
  audioplayers: ^5.2.1
  ffi: ^2.1.0
```

## Application Features

- Multi-track timeline with drag-and-drop
- Real-time video preview
- Clip trimming, splitting, and speed control
- Video scaling and positioning
- Text overlays with customization
- Audio waveform visualization
- Multiple aspect ratios (16:9, 9:16, 1:1, 4:3, 21:9)
- Quality presets (4K, 1080p, 720p, 480p)
- Undo/redo functionality
- Keyboard shortcuts

## Installation

```bash
git clone https://github.com/melihgulbay/VideoCut.git
cd VideoCut
flutter pub get
flutter run -d windows
```

## Flutter Skills Demonstrated

**State Management**
- Riverpod StateNotifier pattern
- Immutable state updates
- Provider composition
- Granular rebuild optimization

**UI/UX**
- Custom design system
- Reusable component library
- Material 3 principles
- Responsive layouts
- Smooth animations

**Architecture**
- Clean separation of concerns
- Modular widget composition
- Scalable project structure
- Testable code patterns

**Performance**
- Efficient list rendering
- Debounced updates
- Memory-efficient image handling
- Frame caching strategies

**Advanced Features**
- FFI integration with native code
- Custom rendering with CustomPainter
- Complex gesture handling
- Real-time data synchronization

## License

MIT License
