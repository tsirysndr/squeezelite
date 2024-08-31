const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "squeezelite",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        // .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "squeezelite",
        // .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    exe.addCSourceFiles(.{ .files = &all_sources, .flags = &cflags });

    lib.addCSourceFiles(.{ .files = &all_sources, .flags = &cflags });

    exe.linkSystemLibrary("asound");
    exe.linkSystemLibrary("dl");
    exe.linkSystemLibrary("pthread");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("rt");
    exe.linkLibC();

    lib.linkSystemLibrary("asound");
    lib.linkSystemLibrary("dl");
    lib.linkSystemLibrary("pthread");
    lib.linkSystemLibrary("m");
    lib.linkSystemLibrary("rt");
    lib.linkLibC();
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
