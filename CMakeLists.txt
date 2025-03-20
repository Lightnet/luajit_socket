cmake_minimum_required(VERSION 3.14)
project(LuaSocketTest C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Fetch CPM if not already present
if(NOT EXISTS "${CMAKE_BINARY_DIR}/cmake/CPM.cmake")
    file(DOWNLOAD
        "https://github.com/cpm-cmake/CPM.cmake/releases/latest/download/CPM.cmake"
        "${CMAKE_BINARY_DIR}/cmake/CPM.cmake"
    )
endif()
include(${CMAKE_BINARY_DIR}/cmake/CPM.cmake)

# Add LuaJIT using CPM
CPMAddPackage(
    NAME luajit
    GITHUB_REPOSITORY LuaJIT/LuaJIT 
    GIT_TAG v2.1
    DOWNLOAD_ONLY YES
)

# Define LuaJIT DLL and import library paths
set(LUAJIT_DLL "${luajit_SOURCE_DIR}/src/lua51.dll")
set(LUAJIT_LIB "${luajit_SOURCE_DIR}/src/lua51.lib")

# Ensure LuaJIT src directory exists and build DLL only if missing
if(NOT EXISTS ${luajit_SOURCE_DIR}/src)
    message(FATAL_ERROR "LuaJIT source directory not found: ${luajit_SOURCE_DIR}/src")
endif()

if(NOT EXISTS ${LUAJIT_DLL} OR NOT EXISTS ${LUAJIT_LIB})
    message(STATUS "Building LuaJIT DLL...")
    execute_process(
        COMMAND cmd /c msvcbuild.bat dll
        WORKING_DIRECTORY ${luajit_SOURCE_DIR}/src
        RESULT_VARIABLE LUAJIT_BUILD_RESULT
        OUTPUT_VARIABLE LUAJIT_BUILD_OUTPUT
        ERROR_VARIABLE LUAJIT_BUILD_ERROR
    )
    if(NOT LUAJIT_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to build LuaJIT:\nOutput: ${LUAJIT_BUILD_OUTPUT}\nError: ${LUAJIT_BUILD_ERROR}")
    endif()
    if(NOT EXISTS ${LUAJIT_DLL} OR NOT EXISTS ${LUAJIT_LIB})
        message(FATAL_ERROR "LuaJIT DLL or LIB not found after build: ${LUAJIT_DLL}, ${LUAJIT_LIB}")
    endif()
else()
    message(STATUS "LuaJIT DLL and LIB already exist, skipping build.")
endif()

# Add LuaSocket using CPM
CPMAddPackage(
    NAME luasocket
    GITHUB_REPOSITORY lunarmodules/luasocket 
    GIT_TAG v3.1.0
)

# Define LuaSocket source files (Windows-specific)
set(LUASOCKET_SRC
    "${luasocket_SOURCE_DIR}/src/luasocket.c"  # Defines luaopen_socket_core
    "${luasocket_SOURCE_DIR}/src/timeout.c"
    "${luasocket_SOURCE_DIR}/src/buffer.c"
    "${luasocket_SOURCE_DIR}/src/io.c"
    "${luasocket_SOURCE_DIR}/src/auxiliar.c"
    "${luasocket_SOURCE_DIR}/src/options.c"
    "${luasocket_SOURCE_DIR}/src/inet.c"
    "${luasocket_SOURCE_DIR}/src/tcp.c"
    "${luasocket_SOURCE_DIR}/src/udp.c"
    "${luasocket_SOURCE_DIR}/src/except.c"
    "${luasocket_SOURCE_DIR}/src/select.c"
    "${luasocket_SOURCE_DIR}/src/compat.c"
)
if(WIN32)
    list(APPEND LUASOCKET_SRC "${luasocket_SOURCE_DIR}/src/wsocket.c")
else()
    list(APPEND LUASOCKET_SRC "${luasocket_SOURCE_DIR}/src/usocket.c")
endif()

# Verify source files exist
foreach(src_file ${LUASOCKET_SRC})
    if(NOT EXISTS ${src_file})
        message(FATAL_ERROR "Missing LuaSocket source file: ${src_file}")
    endif()
endforeach()

# Define LuaSocket DLL and LIB paths
set(LUASOCKET_DLL "${CMAKE_BINARY_DIR}/socket.dll")
set(LUASOCKET_LIB "${CMAKE_BINARY_DIR}/socket.lib")

# Build LuaSocket as a shared library (DLL) only if missing
if(NOT EXISTS ${LUASOCKET_DLL} OR NOT EXISTS ${LUASOCKET_LIB})
    message(STATUS "Building LuaSocket DLL...")
    add_library(luasocket SHARED ${LUASOCKET_SRC})
    set_target_properties(luasocket PROPERTIES 
        OUTPUT_NAME "socket"  # Outputs socket.dll and socket.lib
    )
    target_include_directories(luasocket PUBLIC 
        "${luajit_SOURCE_DIR}/src"
        "${luasocket_SOURCE_DIR}/src"
    )
    target_link_libraries(luasocket PRIVATE 
        ${LUAJIT_LIB}
        ws2_32
    )
    if(MSVC)
        target_compile_definitions(luasocket PRIVATE 
            _CRT_SECURE_NO_WARNINGS 
            _WINSOCK_DEPRECATED_NO_WARNINGS
            "luaopen_socket_core=luaopen_socket"  # Rename entry point for require('socket')
        )
    endif()
else()
    message(STATUS "LuaSocket DLL and LIB already exist, skipping build.")
    # Add an imported library target for linking without rebuilding
    add_library(luasocket SHARED IMPORTED)
    set_target_properties(luasocket PROPERTIES 
        IMPORTED_LOCATION "${LUASOCKET_DLL}"
        IMPORTED_IMPLIB "${LUASOCKET_LIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${luajit_SOURCE_DIR}/src;${luasocket_SOURCE_DIR}/src"
    )
endif()

# Define the main executable
add_executable(${PROJECT_NAME} main.c)
target_include_directories(${PROJECT_NAME} PRIVATE 
    "${luajit_SOURCE_DIR}/src"
    "${luasocket_SOURCE_DIR}/src"
)
target_link_libraries(${PROJECT_NAME} PRIVATE 
    ${LUAJIT_LIB}
)

# Copy LuaJIT DLL, LuaSocket DLL, and main.lua to output directory
set(OUTPUT_DIR $<TARGET_FILE_DIR:${PROJECT_NAME}>)
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${LUAJIT_DLL} ${OUTPUT_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${LUASOCKET_DLL} ${OUTPUT_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_SOURCE_DIR}/main.lua" ${OUTPUT_DIR}
    COMMENT "Copying LuaJIT DLL, LuaSocket DLL, and main.lua to output directory"
)

# Debug output to verify paths
# message(STATUS "LuaJIT source: ${luajit_SOURCE_DIR}")
# message(STATUS "LuaSocket source: ${luasocket_SOURCE_DIR}")
# message(STATUS "LuaSocket sources: ${LUASOCKET_SRC}")
# message(STATUS "LuaSocket DLL: ${LUASOCKET_DLL}")
# message(STATUS "LuaSocket LIB: ${LUASOCKET_LIB}")