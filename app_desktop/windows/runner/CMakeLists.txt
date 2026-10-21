cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

add_dependencies(${BINARY_NAME} fardesk_stream_core)

set(FARDESK_LIBTAILSCALE_DLL
  "${CMAKE_CURRENT_SOURCE_DIR}/../../../.tools/libtailscale/windows-x64/libtailscale.dll"
)

add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "$<TARGET_FILE:fardesk_stream_core>"
    "$<TARGET_FILE_DIR:${BINARY_NAME}>"
)

if(EXISTS "${FARDESK_LIBTAILSCALE_DLL}")
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${FARDESK_LIBTAILSCALE_DLL}"
      "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  )
else()
  message(WARNING
    "libtailscale.dll was not found. Run scripts/build-libtailscale.ps1 before using the FarDesk network runtime."
  )
endif()

set(FARDESK_TAILSCALE_DIR
  "${CMAKE_CURRENT_SOURCE_DIR}/../../../.tools/tailscale/windows-x64"
)
foreach(_tailscale_binary tailscale.exe tailscaled.exe)
  if(EXISTS "${FARDESK_TAILSCALE_DIR}/${_tailscale_binary}")
    add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_FILE_DIR:${BINARY_NAME}>/network"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${FARDESK_TAILSCALE_DIR}/${_tailscale_binary}"
        "$<TARGET_FILE_DIR:${BINARY_NAME}>/network/${_tailscale_binary}"
    )
  else()
    message(WARNING
      "${_tailscale_binary} was not found. Run scripts/build-tailscale-windows.ps1 before using the embedded TUN runtime."
    )
  endif()
endforeach()

# As DLLs do FFmpeg (usadas pelo fardesk_stream_core) precisam ficar ao lado
# do executável final, não só ao lado do fardesk_stream_core.dll.
file(GLOB FARDESK_FFMPEG_DLLS "${FARDESK_FFMPEG_ROOT}/bin/*.dll")
foreach(_dll ${FARDESK_FFMPEG_DLLS})
  add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${_dll}"
      "$<TARGET_FILE_DIR:${BINARY_NAME}>"
  )
endforeach()

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
