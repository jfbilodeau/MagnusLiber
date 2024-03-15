cmake_minimum_required(VERSION 3.27)

project(MagnusLiber)

set(CMAKE_CXX_STANDARD 20)
set(BUILD_SHARED_LIBS OFF)

set(Boost_USE_STATIC_LIBS ON)

find_package(Boost REQUIRED COMPONENTS system json url)
find_package(OpenSSL REQUIRED)

add_executable(MagnusLiber main.cpp)

#include_directories(${Boost_INCLUDE_DIRS})
#include_directories(${openssl_INCLUDE_DIRS})

target_link_libraries(
    MagnusLiber
    PRIVATE

    Boost::boost
    Boost::system
    Boost::json
    Boost::url

    OpenSSL::SSL
    OpenSSL::Crypto
)
