cmake_minimum_required(VERSION 3.15)
project(videocut_native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Set FFmpeg path
set(FFMPEG_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../ffmpeg/ffmpeg-master-latest-win64-gpl-shared")

# Find FFmpeg
if(EXISTS "${FFMPEG_ROOT}")
    message(STATUS "Using local FFmpeg at: ${FFMPEG_ROOT}")
    
    set(FFMPEG_INCLUDE_DIRS "${FFMPEG_ROOT}/include")
    set(FFMPEG_LIBRARY_DIRS "${FFMPEG_ROOT}/lib")
    
    # Find all FFmpeg libraries
    find_library(AVCODEC_LIBRARY avcodec PATHS "${FFMPEG_LIBRARY_DIRS}" NO_DEFAULT_PATH)
    find_library(AVFORMAT_LIBRARY avformat PATHS "${FFMPEG_LIBRARY_DIRS}" NO_DEFAULT_PATH)
    find_library(AVUTIL_LIBRARY avutil PATHS "${FFMPEG_LIBRARY_DIRS}" NO_DEFAULT_PATH)
    find_library(AVFILTER_LIBRARY avfilter PATHS "${FFMPEG_LIBRARY_DIRS}" NO_DEFAULT_PATH)
    find_library(SWSCALE_LIBRARY swscale PATHS "${FFMPEG_LIBRARY_DIRS}" NO_DEFAULT_PATH)
    find_library(SWRESAMPLE_LIBRARY swresample PATHS "${FFMPEG_LIBRARY_DIRS}" NO_DEFAULT_PATH)
    
    set(FFMPEG_FOUND TRUE)
    message(STATUS "FFmpeg libraries found:")
    message(STATUS "  avcodec: ${AVCODEC_LIBRARY}")
    message(STATUS "  avformat: ${AVFORMAT_LIBRARY}")
    message(STATUS "  avutil: ${AVUTIL_LIBRARY}")
    message(STATUS "  avfilter: ${AVFILTER_LIBRARY}")
    message(STATUS "  swscale: ${SWSCALE_LIBRARY}")
    message(STATUS "  swresample: ${SWRESAMPLE_LIBRARY}")
else()
    message(FATAL_ERROR "FFmpeg not found at ${FFMPEG_ROOT}")
endif()

# Source files
set(SOURCES
    src/video_engine.cpp
    src/audio_engine.cpp
    src/timeline.cpp
    src/exporter.cpp
    src/renderer.cpp
    src/api.cpp
)

set(HEADERS
    include/video_engine.h
    include/audio_engine.h
    include/timeline.h
    include/exporter.h
    include/renderer.h
    include/types.h
    include/api.h
)

include_directories(include)

# Create shared library
add_library(videocut_native SHARED
    src/api.cpp
    src/video_engine.cpp
    src/audio_engine.cpp
    src/timeline.cpp
    src/renderer.cpp
    src/exporter.cpp
    src/simple_text_renderer.cpp
)

target_include_directories(videocut_native PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${FFMPEG_INCLUDE_DIRS}
)

# Link FFmpeg libraries
target_link_libraries(videocut_native PRIVATE
    ${AVCODEC_LIBRARY}
    ${AVFORMAT_LIBRARY}
    ${AVUTIL_LIBRARY}
    ${AVFILTER_LIBRARY}
    ${SWSCALE_LIBRARY}
    ${SWRESAMPLE_LIBRARY}
)

# Copy FFmpeg DLLs to output directory on Windows
if(WIN32)
    file(GLOB FFMPEG_DLLS "${FFMPEG_ROOT}/bin/*.dll")
 foreach(DLL ${FFMPEG_DLLS})
   get_filename_component(DLL_NAME ${DLL} NAME)
  add_custom_command(TARGET videocut_native POST_BUILD
         COMMAND ${CMAKE_COMMAND} -E copy_if_different
       "${DLL}"
         "$<TARGET_FILE_DIR:videocut_native>/${DLL_NAME}"
    COMMENT "Copying ${DLL_NAME}"
     )
    endforeach()
endif()

# Platform-specific settings
if(WIN32)
  set_target_properties(videocut_native PROPERTIES OUTPUT_NAME "videocut_native")
  
    # Copy DLL to Flutter lib directory for development
    add_custom_command(TARGET videocut_native POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
         "$<TARGET_FILE:videocut_native>"
      "${CMAKE_CURRENT_SOURCE_DIR}/../lib/videocut_native.dll"
    COMMENT "Copying videocut_native.dll to Flutter lib directory"
    )
    
    # Copy DLL to Flutter build directories
    add_custom_command(TARGET videocut_native POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
       "${CMAKE_CURRENT_SOURCE_DIR}/../build/windows/x64/runner/Release"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:videocut_native>"
            "${CMAKE_CURRENT_SOURCE_DIR}/../build/windows/x64/runner/Release/videocut_native.dll"
    COMMENT "Copying videocut_native.dll to Flutter Release build directory"
    )
    
    add_custom_command(TARGET videocut_native POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
          "${CMAKE_CURRENT_SOURCE_DIR}/../build/windows/x64/runner/Debug"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:videocut_native>"
            "${CMAKE_CURRENT_SOURCE_DIR}/../build/windows/x64/runner/Debug/videocut_native.dll"
     COMMENT "Copying videocut_native.dll to Flutter Debug build directory"
    )
    
elseif(APPLE)
    set_target_properties(videocut_native PROPERTIES OUTPUT_NAME "videocut_native")
else()
    set_target_properties(videocut_native PROPERTIES OUTPUT_NAME "videocut_native")
endif()

target_include_directories(videocut_native PRIVATE
   ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${FFMPEG_INCLUDE_DIR}
)

target_link_libraries(videocut_native PRIVATE
    ${FFMPEG_AVCODEC}
    ${FFMPEG_AVFORMAT}
    ${FFMPEG_AVUTIL}
    ${FFMPEG_AVFILTER}
    ${FFMPEG_SWSCALE}
    ${FFMPEG_SWRESAMPLE}
)

# Copy DLL to lib folder for Flutter to find
