const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zaudio = b.dependency("zaudio", .{});

    const zing_module = b.addModule(
        "zing",
        .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        },
    );
    zing_module.addImport("zaudio", zaudio.module("root"));
    zing_module.linkLibrary(zaudio.artifact("miniaudio"));

    const example_module = b.createModule(
        .{
            .root_source_file = b.path("src/example.zig"),
            .target = target,
            .optimize = optimize,
        },
    );
    example_module.addImport("zing", zing_module);
    const example_exe = b.addExecutable(.{
        .name = "zing_example",
        .root_module = example_module,
    });
    b.installArtifact(example_exe);
    const example_cmd = b.addRunArtifact(example_exe);
    example_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("example", "Run the example");
    run_step.dependOn(&example_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
