# Minimum CMake required
cmake_minimum_required(VERSION 2.8)

# Project
project(Quote C CXX)

if(NOT MSVC)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
else()
  add_definitions(-D_WIN32_WINNT=0x600)
endif()

add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")

# Protobuf
# NOTE: we cannot use "CONFIG" mode here because protobuf-config.cmake
# is broken when used with CMAKE_INSTALL_PREFIX
find_package(Protobuf REQUIRED)
message(STATUS "Using protobuf ${protobuf_VERSION}")

# {Protobuf,PROTOBUF}_FOUND is defined based on find_package type ("MODULE" vs "CONFIG").
# For "MODULE", the case has also changed between cmake 3.5 and 3.6.
# We use the legacy uppercase version for *_LIBRARIES AND *_INCLUDE_DIRS variables
# as newer cmake versions provide them too for backward compatibility.
if(Protobuf_FOUND OR PROTOBUF_FOUND)
  if(TARGET protobuf::libprotobuf)
    set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
  else()
    set(_PROTOBUF_LIBPROTOBUF ${PROTOBUF_LIBRARIES})
    include_directories(${PROTOBUF_INCLUDE_DIRS})
  endif()
  if(TARGET protobuf::protoc)
    set(_PROTOBUF_PROTOC $<TARGET_FILE:protobuf::protoc>)
  else()
    set(_PROTOBUF_PROTOC ${PROTOBUF_PROTOC_EXECUTABLE})
  endif()
else()
  message(WARNING "Failed to locate libprotobuf and protoc!")
endif()

# gRPC
find_package(gRPC CONFIG REQUIRED)
message(STATUS "Using gRPC ${gRPC_VERSION}")

# gRPC C++ plugin
get_target_property(gRPC_CPP_PLUGIN_EXECUTABLE gRPC::grpc_cpp_plugin
    IMPORTED_LOCATION_DEBUG)

# Proto file
get_filename_component(qs_proto "../protos/quote_service.proto" ABSOLUTE)
get_filename_component(qs_proto_path "${qs_proto}" PATH)
get_filename_component(df_proto "../protos/data_define.proto" ABSOLUTE)
get_filename_component(df_proto_path "${df_proto}" PATH)

# Generated sources
protobuf_generate_cpp(qs_proto_srcs qs_proto_hdrs "${qs_proto}")
set(qs_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/quote_service.grpc.pb.cc")
set(qs_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/quote_service.grpc.pb.h")
add_custom_command(
      OUTPUT "${qs_grpc_srcs}" "${qs_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}" -I "${qs_proto_path}"
        --plugin=protoc-gen-grpc="${gRPC_CPP_PLUGIN_EXECUTABLE}"
        "${qs_proto}"
      DEPENDS "${qs_proto}")

protobuf_generate_cpp(df_proto_srcs df_proto_hdrs "${df_proto}")
set(df_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/data_define.grpc.pb.cc")
set(df_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/data_define.grpc.pb.h")
add_custom_command(
      OUTPUT "${df_grpc_srcs}" "${df_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}" -I "${df_proto_path}"
        --plugin=protoc-gen-grpc="${gRPC_CPP_PLUGIN_EXECUTABLE}"
        "${df_proto}"
      DEPENDS "${df_proto}")

# Generated include directory
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# Targets greeter_[async_](client|server)
foreach(_target
  quote_async_bidi_client quote_async_bidi_server)
  add_executable(${_target} "${_target}.cc"
    ${qs_proto_srcs}
    ${qs_grpc_srcs}
	${df_proto_srcs}
    ${df_grpc_srcs})
  target_link_libraries(${_target}
    ${_PROTOBUF_LIBPROTOBUF}
    gRPC::grpc++_unsecure)
endforeach()
