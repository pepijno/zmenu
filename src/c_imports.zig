pub const c = @cImport({
    @cInclude("X11/Xatom.h");
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("X11/extensions/Xinerama.h");
    @cInclude("X11/Xft/Xft.h");
    @cInclude("locale.h");
    @cInclude("stdio.h");
    @cInclude("fontconfig/fontconfig.h");
    @cInclude("time.h");
});
