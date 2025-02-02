# zgui SDL3 GPU API Example

This examle uses a fork of [zgui](https://github.com/zig-gamedev/zgui) to demonstrate how to
possibly integrate with the SDL3 GPU API. It depends on the latest version of
[SDL](https://github.com/libsdl-org/SDL) on github because
[zsdl](https://github.com/zig-gamedev/zsdl) doesn't have bindings for the new GPU API (at
the moment of writing this). 

This example is based on
[this one](https://github.com/ocornut/imgui/blob/master/examples/example_sdl3_sdlgpu3/main.cpp)
from [imgui](https://github.com/ocornut/imgui/tree/master) and
[this one](https://github.com/zig-gamedev/zig-gamedev/blob/main/samples/minimal_zgui_glfw_gl/src/minimal_zgui_glfw_gl.zig)
from the [zig-gamedev](https://github.com/zig-gamedev/zig-gamedev/tree/main) samples.

Finally, this was only tested on Windows, but should work on other platforms.

## Building and Running

```
# 1. Fetch the SDL repo
git submodule init
git submodule udpate
# 2. Build the SDL3 .dll
cd SDL
mkdir build && cd build
cmake -G "MinGW Makefiles" .. && cmake --build .
cd ../..
# 3. Run the example
zig build run
```
