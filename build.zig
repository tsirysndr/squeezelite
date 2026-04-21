const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const is_linux = target.result.os.tag == .linux;

    const lib_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    lib_module.addCSourceFiles(.{ .files = &all_sources, .flags = &cflags });
    lib_module.addIncludePath(b.path("."));
    if (!is_linux) lib_module.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
    if (is_linux) lib_module.linkSystemLibrary("asound", .{});
    lib_module.linkSystemLibrary("dl", .{});
    lib_module.linkSystemLibrary("pthread", .{});
    lib_module.linkSystemLibrary("m", .{});
    if (is_linux) lib_module.linkSystemLibrary("rt", .{});

    const lib = b.addLibrary(.{
        .name = "squeezelite",
        .root_module = lib_module,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const exe_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    exe_module.addCSourceFiles(.{ .files = &all_sources, .flags = &cflags });
    exe_module.addIncludePath(b.path("."));
    if (!is_linux) {
        exe_module.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });
        exe_module.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
        exe_module.linkSystemLibrary("portaudio", .{});
    }
    if (is_linux) exe_module.linkSystemLibrary("asound", .{});
    exe_module.linkSystemLibrary("dl", .{});
    exe_module.linkSystemLibrary("pthread", .{});
    exe_module.linkSystemLibrary("m", .{});
    if (is_linux) exe_module.linkSystemLibrary("rt", .{});

    const exe = b.addExecutable(.{
        .name = "squeezelite",
        .root_module = exe_module,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}

const all_sources = [_][]const u8{
    "main.c",
    "slimproto.c",
    "buffer.c",
    "stream.c",
    "utils.c",
    "output.c",
    "output_alsa.c",
    "output_pa.c",
    "output_stdout.c",
    "output_pack.c",
    "output_pulse.c",
    "decode.c",
    "flac.c",
    "pcm.c",
    "vorbis.c",
    // dsd
    "dsd.c",
    "dop.c",
    "dsd2pcm/dsd2pcm.c",
    // ffmpeg
    "ffmpeg.c",
    // alac
    // "alac.c",
    // "alac_wrapper.cpp",
    // resample
    "process.c",
    "resample.c",
    // vis
    "output_vis.c",
    // ir
    "ir.c",
    // "gpio.c",
    "faad.c",
    // "sslsym.c",
    "opus.c",
    "mad.c",
    "mpg.c",
};

const cflags = [_][]const u8{ "-std=gnu99", "-Wall", "-fPIC", "-O2", "-fcommon" };
