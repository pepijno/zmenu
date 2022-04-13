const std = @import("std");
const c = @import("c_imports.zig").c;
const Draw = @import("draw.zig").Draw;

var fonts: []const []const u8 = &.{
    "monospace:size=10"
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

const ZMENU_VERSION = "0.0.1";

var topbar: bool = true;
var left_right_padding: u32 = 0;

var stdin_items = std.ArrayList([]const u8).init(allocator);

var lines: u32 = 0;

fn cDefaultRootWindow(display: *c.Display) c_ulong {
    const screen = cDefaultScreen(display);
    return @intCast(c_ulong, cRootWindow(display, screen));
}

fn cDefaultScreen(display: *c.Display) c_int {
    return @ptrCast(c._XPrivDisplay, @alignCast(std.meta.alignment(*c._XPrivDisplay), display)).*.default_screen;
}

fn cRootWindow(display: *c.Display, screen: c_int) c.Window {
    return @ptrCast(c._XPrivDisplay, @alignCast(std.meta.alignment(*c._XPrivDisplay), display)).*.screens[@intCast(usize, screen)].root;
}

fn grabKeyboard(display: *c.Display) !void {
    // if (embed) return;
    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        if (c.XGrabKeyboard(display, cDefaultRootWindow(display), 1, c.GrabModeAsync, c.GrabModeAsync, c.CurrentTime) == c.GrabSuccess) {
            return;
        }
        std.time.sleep(1000000);
    }
    try die ("cannot grab keyboard", .{});
}

fn readStdin() !void {
    var buffer: [255]u8 = undefined;
    while (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |user_input| {
        try stdin_items.append(user_input);
    }
    lines = std.math.min(lines, stdin_items.items.len);
}

fn usage() !void {
    try stderr.print("usage: zmenu [-bfiv] [-l lines] [-p prompt] [-fn font] [-m monitor]\n", .{});
    try stderr.print("             [-nb color] [-nf color] [-sb color] [-sf color] [-w windowid]\n", .{});
    std.process.exit(1);
}

fn die(comptime format: []const u8, args: anytype) !void {
    try stderr.print(format, args);
    std.process.exit(1);
}

pub fn main() anyerror!void {
    var fast = false;

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    while (args.next(allocator)) |arg| {
        const argument = try arg;

        if (std.mem.eql(u8, argument, "-v")) {
            try stdout.print("zmenu-{s}\n", .{ZMENU_VERSION});
            std.process.exit(0);
        } else if (std.mem.eql(u8, argument, "-b")) {
            topbar = false;
        } else if (std.mem.eql(u8, argument, "-f")) {
            fast = true;
        } else if (std.mem.eql(u8, argument, "-i")) {
            // TODO case insensitive matching
        } else {
            try usage();
        }
    }

    if (c.setlocale(c.LC_CTYPE, "") == null or c.XSupportsLocale() == 0) {
        try stderr.print("warning: no locale support\n", .{});
    }

    var display = c.XOpenDisplay(null) orelse @panic("cannot open dislay");
    defer _ = c.XCloseDisplay(display);

    var screen = cDefaultScreen(display);
    var root = cRootWindow(display, screen);

    // TODO: embedding
    var parent_window = root;

    var window_attributes: c.XWindowAttributes = undefined;
    if (c.XGetWindowAttributes(display, parent_window, &window_attributes) == 0) {
        try die("could not get embedding window attrbutes: 0x{x}", .{parent_window});
    }

    var draw = Draw.init(allocator, display, screen, root, 20, 20);
    defer draw.deinit();

    const fonts_created = try draw.fontsetInit(fonts);
    if (!fonts_created) {
        try die("no fonts could be loaded.", .{});
    }

    left_right_padding = draw.fonts.items[0].h;

    // TODO: something something openBSD

    if (fast and std.c.isatty(0) == 0) {
        try grabKeyboard(display);
        try readStdin();
    } else {
        try readStdin();
        try grabKeyboard(display);
    }

    std.process.exit(0);
}
