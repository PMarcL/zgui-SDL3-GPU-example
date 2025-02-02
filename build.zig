const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zgui = b.dependency("zgui", .{
        .target = target,
        .backend = .sdl3_gpu,
    });
    const exe = b.addExecutable(.{
        .name = "zgui-sdl3-gpu-example",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.want_lto = false;
    exe.root_module.addImport("zgui", zgui.module("root"));
    exe.linkLibrary(zgui.artifact("imgui"));
    exe.addIncludePath(b.path("sdl/include"));
    exe.addLibraryPath(b.path("sdl/build"));
    b.installBinFile("sdl/build/SDL3.dll", "SDL3.dll");
    exe.linkSystemLibrary("sdl3");
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
