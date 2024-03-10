cmake_minimum_required(VERSION 3.28)

project(MagnusLiber)

include(FetchContent)

set(FETCHCONTENT_QUIET OFF)

set(CMAKE_CXX_STANDARD 20)
#set(Boost_USE_STATIC_LIBS ON)
#set(Boost_USE_STATIC_RUNTIME ON)

FetchContent_Declare(
    Boost
    GIT_REPOSITORY https://github.com/boostorg/boost.git
    GIT_TAG        boost-1.84.0
    GIT_SHALLOW    TRUE
    GIT_PROGRESS   TRUE
    OVERRIDE_FIND_PACKAGE
)

# Options for libcurl
set(BUILD_CURL_EXE OFF CACHE BOOL "" FORCE)
set(BUILD_STATIC_LIBS ON CACHE BOOL "" FORCE)
set(CURL_DISABLE_INSTALL ON CACHE BOOL "" FORCE)
set(BUILD_LIBCURL_DOCS OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    CURL
    GIT_REPOSITORY https://github.com/curl/curl.git
    GIT_TAG        curl-8_6_0
    GIT_SHALLOW    TRUE
    GIT_PROGRESS   TRUE
    OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(
    CURL
    Boost
)

#find_package(curl CONFIG REQUIRED)
find_package(Boost REQUIRED json)
find_package(CURL REQUIRED)

add_executable(MagusLiber main.cpp)

target_link_libraries(MagusLiber Boost::json CURL::libcurl)