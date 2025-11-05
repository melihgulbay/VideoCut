@echo off
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=2& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/avcodec-62.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/avcodec-62.dll || (set FAIL_LINE=3& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=4& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/avdevice-62.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/avdevice-62.dll || (set FAIL_LINE=5& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=6& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/avfilter-11.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/avfilter-11.dll || (set FAIL_LINE=7& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=8& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/avformat-62.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/avformat-62.dll || (set FAIL_LINE=9& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=10& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/avutil-60.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/avutil-60.dll || (set FAIL_LINE=11& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=12& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/swresample-6.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/swresample-6.dll || (set FAIL_LINE=13& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=14& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared/bin/swscale-9.dll C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/swscale-9.dll || (set FAIL_LINE=15& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=16& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/videocut_native.dll C:/Users/mehme/Desktop/VideoCut/native/../lib/videocut_native.dll || (set FAIL_LINE=17& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=18& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E make_directory C:/Users/mehme/Desktop/VideoCut/native/../build/windows/x64/runner/Release || (set FAIL_LINE=19& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/videocut_native.dll C:/Users/mehme/Desktop/VideoCut/native/../build/windows/x64/runner/Release/videocut_native.dll || (set FAIL_LINE=20& goto :ABORT)
cd /D C:\Users\mehme\Desktop\VideoCut\native\out\build\x64-Debug || (set FAIL_LINE=21& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E make_directory C:/Users/mehme/Desktop/VideoCut/native/../build/windows/x64/runner/Debug || (set FAIL_LINE=22& goto :ABORT)
"C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" -E copy_if_different C:/Users/mehme/Desktop/VideoCut/native/out/build/x64-Debug/videocut_native.dll C:/Users/mehme/Desktop/VideoCut/native/../build/windows/x64/runner/Debug/videocut_native.dll || (set FAIL_LINE=23& goto :ABORT)
goto :EOF

:ABORT
set ERROR_CODE=%ERRORLEVEL%
echo Batch file failed at line %FAIL_LINE% with errorcode %ERRORLEVEL%
exit /b %ERROR_CODE%