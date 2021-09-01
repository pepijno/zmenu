const std = @import("std");
const c = @import("c_imports.zig").c;

const Draw = @import("draw.zig").Draw;

var parentWindow: c.Window = std.mem.zeroes(c.Window);
var root: c.Window = std.mem.zeroes(c.Window);
var screen: c_int = std.mem.zeroes(c_int);
var lrpad: u32 = undefined;

var fonts: std.ArrayList([]const u8) = std.ArrayList([]const u8).init(std.testing.allocator);

fn setup() void {}

fn run(display: *c.Display, window: c.Window) void {
    std.debug.print("Running...\n", .{});
    var ev: c.XEvent = undefined;
    while (c.XNextEvent(display, &ev) == 0) {
        std.debug.print("YO!\n", .{});
        if (c.XFilterEvent(&ev, window) != 0) {
            continue;
        }
        switch (ev.type) {
            c.DestroyNotify => {
                break;
            },
            c.Expose => {
                break;
            },
            c.FocusIn => {
                break;
            },
            c.KeyPress => {
                std.debug.print("Key is pressed", .{});
                break;
            },
            c.SelectionNotify => {
                break;
            },
            c.VisibilityNotify => {
                break;
            },
            else => {},
        }
    }
}

pub fn main() anyerror!void {
    try fonts.append("monospace:size=10");
    var display: ?*c.Display = std.mem.zeroes(?*c.Display);
    var window: c.Window = std.mem.zeroes(c.Window);
    var window_attributes: c.XWindowAttributes = undefined;

    if (c.setlocale(c.LC_CTYPE, "") == null or c.XSupportsLocale() == 0) {
        @panic("No support for locale");
    }

    display = c.XOpenDisplay(@as(?*u8, null));
    if (display == null) {
        @panic("cannot open display");
    }
    screen = @ptrCast(c._XPrivDisplay, @alignCast(std.meta.alignment(*c._XPrivDisplay), display.?)).*.default_screen;
    root = @ptrCast(c._XPrivDisplay, @alignCast(std.meta.alignment(*c._XPrivDisplay), display.?)).*.screens[@intCast(usize, screen)].root;
    parentWindow = root;

    if (c.XGetWindowAttributes(display, parentWindow, &window_attributes) == 0) {
        @panic("Could not get embedding window attributes: 0x%lx");
    }

    var draw: Draw = Draw.create(display.?, screen, root, @intCast(u32, window_attributes.width), @intCast(u32, window_attributes.height));
    try draw.createFontset(fonts);
    if (draw.fonts.items.len == 0) {
        @panic("no fonts could be loaded.");
    }
    lrpad = draw.fonts.items[0].height;

    run(display.?, window);
}
