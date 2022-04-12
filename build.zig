const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    const mode = b.standardReleaseOptions();

    const zmenu = b.addExecutable("zmenu", "src/main.zig");
    zmenu.setTarget(target);
    zmenu.setBuildMode(mode);
    zmenu.install();
    zmenu.linkLibC();
    zmenu.linkSystemLibrary("c");
    zmenu.linkSystemLibrary("X11");
    zmenu.linkSystemLibrary("Xinerama");
    zmenu.linkSystemLibrary("Xft");
    zmenu.linkSystemLibrary("fontconfig");

    const run_cmd = zmenu.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
