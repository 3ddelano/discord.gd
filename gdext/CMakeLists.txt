cmake_minimum_required(VERSION 3.20)
project(discord_gd_gdext)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set the output directory for the compiled library
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Include FetchContent for dependencies
include(FetchContent)

# godot-cpp path
set(GODOT_CPP_PATH ${CMAKE_SOURCE_DIR}/thirdparty/godot-cpp)

# Include godot-cpp
add_subdirectory(${GODOT_CPP_PATH} godot-cpp)

# Fetch libsodium using CMake wrapper (robinlinden/libsodium-cmake)
FetchContent_Declare(
    libsodium
    GIT_REPOSITORY https://github.com/robinlinden/libsodium-cmake.git
    GIT_TAG        master
)

# Fetch opus
FetchContent_Declare(
    opus
    GIT_REPOSITORY https://github.com/xiph/opus.git
    GIT_TAG        v1.5.2
)

# Configure opus options before making available
set(OPUS_BUILD_SHARED_LIBRARY OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
set(OPUS_INSTALL_PKG_CONFIG_MODULE OFF CACHE BOOL "" FORCE)
set(OPUS_INSTALL_CMAKE_CONFIG_MODULE OFF CACHE BOOL "" FORCE)

# Configure libsodium options
set(SODIUM_DISABLE_TESTS ON CACHE BOOL "" FORCE)

# Manually populate and add with EXCLUDE_FROM_ALL to prevent install
FetchContent_GetProperties(opus)
if(NOT opus_POPULATED)
    FetchContent_Populate(opus)
    add_subdirectory(${opus_SOURCE_DIR} ${opus_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

FetchContent_GetProperties(libsodium)
if(NOT libsodium_POPULATED)
    FetchContent_Populate(libsodium)
    add_subdirectory(${libsodium_SOURCE_DIR} ${libsodium_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# Our GDExtension sources
file(GLOB_RECURSE SOURCES
    src/*.cpp
)

# Create the library
add_library(${PROJECT_NAME} SHARED
    ${SOURCES}
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${GODOT_CPP_PATH}/include
    ${CMAKE_BINARY_DIR}/godot-cpp/gen/include
    ${GODOT_CPP_PATH}/gdextension
    ${opus_SOURCE_DIR}/include
)

# Platform-specific networking libraries
if(WIN32)
    set(PLATFORM_LIBS ws2_32)
elseif(APPLE)
    set(PLATFORM_LIBS)
else()
    set(PLATFORM_LIBS)
endif()

# Link against godot-cpp, opus, libsodium, and platform libs
target_link_libraries(${PROJECT_NAME}
    godot::cpp
    opus
    sodium
    ${PLATFORM_LIBS}
)

# Platform-specific settings
if(WIN32)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "discord_gd_gdext.windows.template_debug.x86_64"
        SUFFIX ".dll"
    )
elseif(APPLE)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "discord_gd_gdext.macos.template_debug"
        SUFFIX ".dylib"
    )
else()
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "discord_gd_gdext.linux.template_debug.x86_64"
        SUFFIX ".so"
    )
endif()

# Install the library and .gdextension file
install(TARGETS ${PROJECT_NAME}
    LIBRARY DESTINATION addons/discord_gd/bin
    RUNTIME DESTINATION addons/discord_gd/bin
)

install(FILES discord_gd.gdextension
    DESTINATION addons/discord_gd
)