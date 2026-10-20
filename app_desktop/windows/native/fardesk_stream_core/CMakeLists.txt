add_library(fardesk_stream_core SHARED fardesk_stream_core.c)

target_include_directories(fardesk_stream_core PRIVATE
  "${moonlight_common_c_SOURCE_DIR}/src"
)

target_link_libraries(fardesk_stream_core PRIVATE moonlight-common-c)
target_compile_definitions(fardesk_stream_core PRIVATE FARDESK_STREAM_CORE_EXPORTS)
target_compile_features(fardesk_stream_core PRIVATE c_std_11)

set_target_properties(fardesk_stream_core PROPERTIES
  OUTPUT_NAME "fardesk_stream_core"
  PREFIX ""
)
