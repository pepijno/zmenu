const std = @import("std");
const c = @import("c_imports.zig").c;

const stderr = std.io.getStdErr();
const stdout = std.io.getStdOut().writer();

const ZMENU_VERSION = "0.0.1";

fn usage() !void {
    _ = try stderr.write("usage: zmenu [-bfiv] [-l lines] [-p prompt] [-fn font] [-m monitor]\n");
    _ = try stderr.write("             [-nb color] [-nf color] [-sb color] [-sf color] [-w windowid]\n");
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    while (args.next(allocator)) |arg| {
        const argument = try arg;
        std.debug.print("{s}\n", .{argument});

        if (std.mem.eql(u8, argument, "-v")) {
            try stdout.print("zmenu-{s}\n", .{ZMENU_VERSION});
            std.process.exit(0);
        } else {
            try usage();
            std.process.exit(1);
        }
    }

    std.process.exit(0);
}
