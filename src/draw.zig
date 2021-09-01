const std = @import("std");
const c = @import("c_imports.zig").c;

pub const Clr = c.XftColor;

pub const Font = struct {
    display: *c.Display,
    height: u32,
    xfont: *c.XftFont,
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
    scheme: ?Clr,
    fonts: std.ArrayList(Font),

    pub fn create(display: *c.Display, screen: i32, root: c.Window, width: u32, height: u32) Self {
        const drawable = createPixmap(display, root, width, height, screen);
        const gc = c.XCreateGC(display, root, 0, null);
        _ = c.XSetLineAttributes(display, gc, 1, c.LineSolid, c.CapButt, c.JoinMiter);
        return .{
            .width = width,
            .height = height,
            .display = display,
            .screen = screen,
            .root = root,
            .drawable = drawable,
            .gc = gc,
            .scheme = null,
            .fonts = std.ArrayList(Font).init(std.testing.allocator),
        };
    }

    fn createXFont(self: *const Self, font_name: ?[]const u8) ?Font {
        if (font_name) |f_name| {
            const x_font: ?*c.XftFont = c.XftFontOpenName(self.display, self.screen, @ptrCast([*c]const u8, @alignCast(std.meta.alignment([*c]const u8), f_name)));
            if (x_font) |font| {
                var is_col: c.FcBool = undefined;
                var res = @enumToInt(c.FcPatternGetBool(font.*.pattern, c.FC_COLOR, 0, &is_col));
                if (res == c.FcResultMatch and is_col != 0) {
                    c.XftFontClose(self.display, font);
                    return null;
                }

                return Font{
                    .xfont = font,
                    .height = @intCast(u32, font.*.ascent + font.*.descent),
                    .display = self.display,
                };
            } else {
                std.debug.print("error, cannot load font from name: {s}\n", .{f_name});
                return null;
            }
        } else {
            @panic("no font specified.");
        }
    }

    pub fn createFontset(self: *Self, fonts: std.ArrayList([]const u8)) !void {
        for (fonts.items) |font| {
            if (self.createXFont(font)) |f| {
                try self.fonts.append(f);
            }
        }
    }

    pub fn resize(self: *Self, width: u32, height: 32) void {
        self.width = width;
        self.height = height;
        _ = c.XFreePixmap(self.display, self.drawable);
        self.drawable = createPixmap(self.display, self.root, self.width, self.height, self.screen);
    }

    pub fn free(self: *Self) void {
        _ = c.XFreePixmap(self.display, self.drawable);
        _ = c.XFreeGC(self.display, self.gc);
        self.freeFontset();
    }
};
