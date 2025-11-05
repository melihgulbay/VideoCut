@echo off
REM VideoCut Build Script for Windows (x64)

echo ========================================
echo   VideoCut Video Editor - Build Script
echo ========================================
echo   Building for x64 architecture
echo ========================================

REM Build C++ native library
echo.
echo [1/5] Building native C++ library...
cd native
if exist build rmdir /s /q build
mkdir build
cd build

REM Configure with CMake using Visual Studio generator for x64
cmake -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release ..
if %errorlevel% neq 0 (
    echo ERROR: CMake configuration failed
    echo.
    echo Trying alternative method with Ninja...
    cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release ..
    if %errorlevel% neq 0 (
  echo ERROR: CMake configuration failed with both generators
        pause
     exit /b 1
    )
)

REM Build
cmake --build . --config Release
if %errorlevel% neq 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

cd ..\..

REM Copy DLLs to all necessary locations
echo.
echo [2/5] Copying DLLs to Flutter directories...

REM Create directories if they don't exist
if not exist "lib" mkdir lib
if not exist "build\windows\x64\runner\Release" mkdir build\windows\x64\runner\Release
if not exist "build\windows\x64\runner\Debug" mkdir build\windows\x64\runner\Debug

REM Copy videocut_native.dll (check both Release and root build folder)
set DLL_FOUND=0
if exist "native\build\Release\videocut_native.dll" (
    copy /Y native\build\Release\videocut_native.dll lib\ >nul
    copy /Y native\build\Release\videocut_native.dll build\windows\x64\runner\Release\ >nul
    copy /Y native\build\Release\videocut_native.dll build\windows\x64\runner\Debug\ >nul
    echo    ? videocut_native.dll copied from Release folder
    set DLL_FOUND=1
)
if exist "native\build\videocut_native.dll" (
    copy /Y native\build\videocut_native.dll lib\ >nul
    copy /Y native\build\videocut_native.dll build\windows\x64\runner\Release\ >nul
    copy /Y native\build\videocut_native.dll build\windows\x64\runner\Debug\ >nul
    echo    ? videocut_native.dll copied from build folder
    set DLL_FOUND=1
)

if %DLL_FOUND%==0 (
    echo    ? ERROR: videocut_native.dll not found!
    pause
    exit /b 1
)

REM Copy FFmpeg DLLs from bin folder
echo    Copying FFmpeg DLLs...
if exist "ffmpeg\ffmpeg-master-latest-win64-gpl-shared\bin\*.dll" (
    copy /Y ffmpeg\ffmpeg-master-latest-win64-gpl-shared\bin\*.dll lib\ >nul
    copy /Y ffmpeg\ffmpeg-master-latest-win64-gpl-shared\bin\*.dll build\windows\x64\runner\Release\ >nul
    copy /Y ffmpeg\ffmpeg-master-latest-win64-gpl-shared\bin\*.dll build\windows\x64\runner\Debug\ >nul
    echo    ? FFmpeg DLLs copied
)

REM Get Flutter dependencies
echo.
echo [3/5] Installing Flutter dependencies...
call flutter pub get >nul 2>&1
if %errorlevel% neq 0 (
    echo    ? Warning: Flutter pub get had issues
) else (
    echo    ? Dependencies installed
)

REM Skip full Flutter build, just ensure DLLs are in place
echo.
echo [4/5] Preparing Flutter debug build...
echo    ? Skipping full release build (use 'flutter build windows' manually if needed)

echo.
echo [5/5] Verifying installation...
if exist "lib\videocut_native.dll" (
    echo    ? lib\videocut_native.dll
) else (
    echo    ? lib\videocut_native.dll MISSING
)

if exist "build\windows\x64\runner\Debug\videocut_native.dll" (
    echo    ? build\windows\x64\runner\Debug\videocut_native.dll
) else (
    echo    ? build\windows\x64\runner\Debug\videocut_native.dll MISSING
)

echo.
echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo To run the app:
echo   flutter run -d windows
echo.
pause
