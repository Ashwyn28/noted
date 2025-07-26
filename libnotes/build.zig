const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Static library for C ABI
    const lib = b.addStaticLibrary(.{
        .name = "notes",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link SQLite
    lib.linkLibC();
    lib.linkSystemLibrary("sqlite3");

    // Install library
    b.installArtifact(lib);

    // Generate header file
    const header_step = b.step("header", "Generate C header file");
    const header_cmd = b.addSystemCommand(&.{ "zig", "build-lib", "-femit-h", "src/main.zig" });
    header_step.dependOn(&header_cmd.step);

    // Tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    unit_tests.linkLibC();
    unit_tests.linkSystemLibrary("sqlite3");

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}