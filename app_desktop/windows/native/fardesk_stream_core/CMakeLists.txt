add_library(fardesk_stream_core SHARED fardesk_stream_core.c)

target_include_directories(fardesk_stream_core PRIVATE
  "${moonlight_common_c_SOURCE_DIR}/src"
  "${FARDESK_FFMPEG_ROOT}/include"
  "${opus_SOURCE_DIR}/include"
)

target_link_directories(fardesk_stream_core PRIVATE "${FARDESK_FFMPEG_ROOT}/lib")

target_link_libraries(fardesk_stream_core PRIVATE
  moonlight-common-c
  opus
  avcodec
  avutil
  swscale
  d3d11
  dxva2
  dxgi
  ole32
  uuid
)
target_compile_definitions(fardesk_stream_core PRIVATE FARDESK_STREAM_CORE_EXPORTS)
target_compile_features(fardesk_stream_core PRIVATE c_std_11)

# Copia as DLLs do FFmpeg para junto do binário final, já que o link é contra
# os .lib de import (shared build).
file(GLOB FARDESK_FFMPEG_DLLS "${FARDESK_FFMPEG_ROOT}/bin/*.dll")
foreach(_dll ${FARDESK_FFMPEG_DLLS})
  add_custom_command(TARGET fardesk_stream_core POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${_dll}"
      "$<TARGET_FILE_DIR:fardesk_stream_core>"
  )
endforeach()

set_target_properties(fardesk_stream_core PROPERTIES
  OUTPUT_NAME "fardesk_stream_core"
  PREFIX ""
)
