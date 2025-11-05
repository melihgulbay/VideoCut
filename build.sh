#!/bin/bash

# VideoCut Build Script

echo "Building VideoCut Video Editor..."

# Build C++ native library
echo "Building native library..."
cd native
mkdir -p build
cd build

# Configure with CMake
cmake ..

# Build
cmake --build . --config Release

# Copy library to Flutter lib directory
if [ -f "libvideocut_native.so" ]; then
    cp libvideocut_native.so ../../lib/
elif [ -f "libvideocut_native.dylib" ]; then
    cp libvideocut_native.dylib ../../lib/
elif [ -f "Release/videocut_native.dll" ]; then
    cp Release/videocut_native.dll ../../lib/
fi

cd ../..

# Get Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get

# Build Flutter app
echo "Building Flutter application..."
flutter build windows --release

echo "Build complete!"
echo "Run the app with: flutter run"
