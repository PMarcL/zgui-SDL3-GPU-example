const std = @import("std");
const zgui = @import("zgui");
const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {
    // Setup SDL
    if (!c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_GAMEPAD)) {
        std.log.err("SDL_Init failed: {s}\n", .{c.SDL_GetError()});
        return;
    }
    defer c.SDL_Quit();

    // Create SDL window graphics context
    const window = c.SDL_CreateWindow(
        "zgui SDL3+GPU example",
        1280,
        720,
        c.SDL_WINDOW_RESIZABLE | c.SDL_WINDOW_HIGH_PIXEL_DENSITY,
    );
    if (window == null) {
        std.log.err("SDL_CreateWindow failed: {s}\n", .{c.SDL_GetError()});
        return;
    }
    defer c.SDL_DestroyWindow(window);

    // Create GPU device
    const device = c.SDL_CreateGPUDevice(
        c.SDL_GPU_SHADERFORMAT_SPIRV | c.SDL_GPU_SHADERFORMAT_DXIL | c.SDL_GPU_SHADERFORMAT_METALLIB,
        true, // debug_mode
        null, // name, e.g. "vulkan", "direct3d12", etc.
    );
    if (device == null) {
        std.log.err("SDL_CreateGPUDevice failed: {s}\n", .{c.SDL_GetError()});
        return;
    }
    defer c.SDL_DestroyGPUDevice(device);

    // Claim window for GPU Device
    if (!c.SDL_ClaimWindowForGPUDevice(device, window)) {
        std.log.err("SDL_ClaimWindowForGPUDevice failed: {s}\n", .{c.SDL_GetError()});
        return;
    }
    defer c.SDL_ReleaseWindowFromGPUDevice(device, window);
    _ = c.SDL_SetGPUSwapchainParameters(
        device,
        window,
        c.SDL_GPU_SWAPCHAINCOMPOSITION_SDR,
        c.SDL_GPU_PRESENTMODE_MAILBOX,
    );

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();
    zgui.init(gpa);
    defer zgui.deinit();

    // Setup Dear ImGui style
    zgui.getStyle().setColorsDark();
    //zgui.getStyle().setColorsLight();

    // Setup Platform/Renderer backends
    zgui.backend.init(window.?, .{
        .device = device.?,
        .color_target_format = c.SDL_GetGPUSwapchainTextureFormat(device, window),
        .msaa_samples = c.SDL_GPU_SAMPLECOUNT_1,
    });
    defer zgui.backend.deinit();

    // Main loop
    var event: c.SDL_Event = undefined;
    mainloop: while (true) {
        while (c.SDL_PollEvent(&event)) {
            _ = zgui.backend.processEvent(&event);
            switch (event.type) {
                c.SDL_EVENT_QUIT => break :mainloop,
                else => {},
            }
        }

        var fb_width: c_int = 0;
        var fb_height: c_int = 0;
        if (!c.SDL_GetWindowSize(window, &fb_width, &fb_height)) {
            std.log.err("SDL_GetWindowSizeInPixels failed: {s}\n", .{c.SDL_GetError()});
            return;
        }
        const fb_scale = c.SDL_GetWindowDisplayScale(window);
        zgui.backend.newFrame(@intCast(fb_width), @intCast(fb_height), fb_scale);

        // Show a simple window
        zgui.setNextWindowPos(.{ .x = 20.0, .y = 20.0, .cond = .first_use_ever });
        zgui.setNextWindowSize(.{ .w = -1.0, .h = -1.0, .cond = .first_use_ever });
        if (zgui.begin("My window", .{})) {
            if (zgui.button("Press me!", .{ .w = 200.0 })) {
                std.log.info("Button pressed!\n", .{});
            }
        }
        zgui.end();

        // The SDL3+GPU backend requires calling zgui.backend.render() before rendering ImGui
        zgui.backend.render();

        const command_buffer = c.SDL_AcquireGPUCommandBuffer(device);
        var swapchain_texture: ?*c.SDL_Texture = null;
        if (!c.SDL_AcquireGPUSwapchainTexture(command_buffer, window, @ptrCast(&swapchain_texture), null, null)) {
            std.log.err("SDL_AcquireGPUSwapchainTexture failed: {s}\n", .{c.SDL_GetError()});
            return;
        }

        if (swapchain_texture != null) {
            // This is mandatory: call prepareDrawData (Imgui_ImplSDLGPU3_PrepareDrawData) to upload the vertex/index buffers.
            zgui.backend.prepareDrawData(@ptrCast(command_buffer));

            // Setup and start a render pass
            const target_info = c.SDL_GPUColorTargetInfo{
                .texture = @ptrCast(swapchain_texture),
                .clear_color = .{ .r = 0.45, .g = 0.55, .b = 0.60, .a = 1.0 },
                .load_op = c.SDL_GPU_LOADOP_CLEAR,
                .store_op = c.SDL_GPU_STOREOP_STORE,
            };
            const render_pass = c.SDL_BeginGPURenderPass(command_buffer, &target_info, 1, null);
            defer c.SDL_EndGPURenderPass(render_pass);

            // Render ImGui
            zgui.backend.renderDrawData(@ptrCast(command_buffer), @ptrCast(render_pass), null);
        }

        if (!c.SDL_SubmitGPUCommandBuffer(command_buffer)) {
            std.log.err("SDL_SubmitGPUCommandBuffer failed: {s}\n", .{c.SDL_GetError()});
            return;
        }
    }
    _ = c.SDL_WaitForGPUIdle(device);
}
