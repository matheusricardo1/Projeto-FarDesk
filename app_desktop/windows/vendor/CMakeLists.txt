# Busca as dependências nativas vendorizadas (moonlight-common-c/enet e
# libopus) num diretório próprio de propósito.
#
# EXCLUDE_FROM_ALL (suportado em FetchContent_Declare desde o CMake 3.28,
# propagando a propriedade de diretório EXCLUDE_FROM_ALL desde o 3.21) tira
# os targets de dentro dessas dependências da instalação padrão do projeto —
# essencial aqui, porque moonlight-common-c/enet e a libopus definem suas
# próprias regras install(TARGETS ...) pras libs estáticas, que nunca usamos
# (só linkamos estaticamente dentro do fardesk_stream_core.dll). Sem isso,
# essas install() de terceiros tentam resolver `${CMAKE_INSTALL_PREFIX}`
# (que contém uma generator expression, usada pelo restante do projeto) e
# quebram: a resolução especial de generator expression só acontece quando
# o próprio install(TARGETS/FILES) referencia o prefixo diretamente no seu
# argumento DESTINATION (como o resto deste projeto faz) — não quando o
# CMake concatena implicitamente um DESTINATION relativo (como "lib/static")
# com CMAKE_INSTALL_PREFIX, caso de ambas essas dependências.
include(FetchContent)

FetchContent_Declare(
  moonlight_common_c
  GIT_REPOSITORY https://github.com/moonlight-stream/moonlight-common-c.git
  GIT_TAG master
  GIT_SHALLOW TRUE
  EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable(moonlight_common_c)

# libopus vendorizada para decodificar o áudio Opus multistream do GameStream
# (mesma API usada pelo moonlight-qt: opus_multistream_decoder_create). Não
# usamos o decoder de opus do FFmpeg porque ele não expõe a API multistream
# com mapeamento de canais que o protocolo exige.
set(OPUS_BUILD_SHARED_LIBRARY OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
set(OPUS_INSTALL_PKG_CONFIG_MODULE OFF CACHE BOOL "" FORCE)
set(OPUS_INSTALL_CMAKE_CONFIG_MODULE OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
  opus
  GIT_REPOSITORY https://github.com/xiph/opus.git
  GIT_TAG v1.5.2
  GIT_SHALLOW TRUE
  EXCLUDE_FROM_ALL
)
FetchContent_MakeAvailable(opus)

# add_subdirectory() (que FetchContent_MakeAvailable chama por baixo)
# propaga PARENT_SCOPE só um nível acima — exatamente o nível que o resto
# do build precisa.
set(moonlight_common_c_SOURCE_DIR "${moonlight_common_c_SOURCE_DIR}" PARENT_SCOPE)
set(opus_SOURCE_DIR "${opus_SOURCE_DIR}" PARENT_SCOPE)
