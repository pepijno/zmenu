const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xatom.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/extensions/Xinerama.h");
    @cInclude("X11/Xft/Xft.h");
});

fn setup() void {}

fn run(display: *c.Display, window: c.Window) void {
    var ev: c.XEvent = undefined;
    while (c.XNextEvent(display, &ev) == 0) {
        if (c.XFilterEvent(&ev, window) != 0) {
            continue;
        }
    }
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
    var opened_display: ?*c.Display = c.XOpenDisplay(@as(?*u8, null));
    if (opened_display == null) {
        @panic("cannot open display");
    }
    var window: c.Window = undefined;
    run(opened_display.?, window);
}
