# C++ OpenAI Example

## Quick start

```shell
cd cpp
cmake -DCMAKE_TOOLCHAIN_FILE=<path_to_vcpkg>/vcpkg.cmake -B ./build
cmake -B ./build -T MagnusLiber
./build/MagnusLiber
```

## Notes

Build using `vcpkg` and `cmake`

Using [Boost](https://www.boost.org) for JSON and HTTPS

There are simpler library for JSON and HTTPS, but I wanted to favour a well-established library this demo.
