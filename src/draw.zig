const std = @import("std");
const c = @import("c_imports.zig").c;

const stderr = std.io.getStdErr().writer();

pub const Font = struct {
    const Self = @This();

    display: *c.Display,
    h: u32,
    x_font: *c.XftFont,
    pattern: ?*c.FcPattern,

    pub fn init(display: *c.Display, screen: c_int, font_name: ?[]const u8, font_pattern: ?*c.FcPattern) !?Self {
        var x_font: *c.XftFont = undefined;
        var pattern: ?*c.FcPattern = undefined;

        if (font_name) |fnt_name| {

            const font = c.XftFontOpenName(display, screen, fnt_name.ptr);
            if (font) |fnt| {
                x_font = fnt;
            } else {
                try stderr.print("error, cannot load font from name: '{s}'\n", .{fnt_name});
                return null;
            }

            const parsed_pattern = c.FcNameParse(fnt_name.ptr);
            if (parsed_pattern) |ptrn| {
                pattern = ptrn;
            } else {
                try stderr.print("error, cannot parse font name to pattern: '{s}'\n", .{fnt_name});
                c.XftFontClose(display, x_font);
                return null;
            }
        } else if (font_pattern) |fnt_pattern| {
            const font = c.XftFontOpenPattern(display, fnt_pattern);
            if (font) |fnt| {
                x_font = fnt;
            } else {
                try stderr.print("error, cannot load font from pattern\n", .{});
                return null;
            }
        } else {
            @panic("no font specified");
        }

        var is_color: c_int = 0;
        if (c.FcPatternGetBool(x_font.pattern, c.FC_COLOR, 0, &is_color) == c.FcResultMatch and is_color == 1) {
            c.XftFontClose(display, x_font);
            return null;
        }

        return Font {
            .x_font = x_font,
            .pattern = pattern,
            .h = @intCast(u32, x_font.ascent + x_font.descent),
            .display = display,
        };
    }
};

pub const ColorType = enum(u2) {
    Foreground,
    Background,
};

fn createPixmap(display: *c.Display, root: c.Window, width: u32, height: u32, screen: i32) c.Drawable {
    const default_depth = @ptrCast(c._XPrivDisplay, @alignCast(std.meta.alignment(*c._XPrivDisplay), display)).*.screens[@intCast(usize, screen)].root_depth;
    return c.XCreatePixmap(display, root, width, height, @intCast(c_uint, default_depth));
}

pub const Draw = struct {
    const Self = @This();

    width: u32,
    height: u32,
    display: *c.Display,
    screen: i32,
    root: c.Window,
    drawable: c.Drawable,
    gc: c.GC,
    scheme: ?*c.XftColor = null,
    fonts: std.ArrayList(Font),

    pub fn init(allocator: std.mem.Allocator, display: *c.Display, screen: i32, root: c.Window, width: u32, height: u32) Self {
        const pixmap = createPixmap(display, root, width, height, screen);
        const gc = c.XCreateGC(display, root, 0, null);

        const draw = Draw {
            .display = display,
            .screen = screen,
            .root = root,
            .width = width,
            .height = height,
            .drawable = pixmap,
            .gc = gc,
            .fonts = std.ArrayList(Font).init(allocator),
        };

        _ = c.XSetLineAttributes(display, draw.gc, 1, c.LineSolid, c.CapButt, c.JoinMiter);

        return draw;
    }

    pub fn deinit(self: *Self) void {
        _ = c.XFreePixmap(self.display, self.drawable);
        _ = c.XFreeGC(self.display, self.gc);
        self.fontsetDeinit();
    }

    pub fn fontsetInit(self: *Self, fonts: []const []const u8) !bool {
        if (fonts.len == 0) {
            return false;
        }

        var counter: u32 = 0;
        while (counter < fonts.len) : (counter += 1) {
            const font = try Font.init(self.display, self.screen, fonts[counter], null);
            if (font) |fnt| {
                try self.fonts.append(fnt);
            }
        }

        return self.fonts.items.len != 0;
    }

    pub fn fontsetDeinit(self: *Self) void {
        for (self.fonts.items) |font| {
            if (font.pattern) |pattern| {
                c.FcPatternDestroy(pattern);
            }
            c.XftFontClose(self.display, font.x_font);
        }
        self.fonts.deinit();
    }
};
