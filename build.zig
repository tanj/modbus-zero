const std = @import("std");

const Test = struct {
    name: []const u8,
    path: []const u8,
};

const tests: []const Test = &.{
    .{ .name = "main", .path = "src/main.zig" },
    .{ .name = "modbus-app-types", .path = "src/mbap_types.zig" },
    .{ .name = "common", .path = "src/common.zig" },
};

pub fn build(b: *std.build.Builder) void {
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
        .name = "modbus",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build test`
    // This will evaluate the `test` step rather than the default, which is "install".
    const test_step = b.step("test", "Run library tests");

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    for (tests) |t| {
        const tst = b.addTest(.{
            .name = t.name,
            .root_source_file = .{ .path = t.path },
            .target = target,
            .optimize = optimize,
        });

        const run_main_tests = b.addRunArtifact(tst);

        test_step.dependOn(&run_main_tests.step);
    }
}
