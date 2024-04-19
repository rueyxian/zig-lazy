const std = @import("std");
const debug = std.debug;
const constLazy = @import("lazy").constLazy;

const getHome = constLazy(struct {
    fn f() []const u8 {
        return std.os.getenv("HOME").?;
    }
}.f);

pub fn main() !void {
    debug.print("home: {s}\n", .{getHome().*});
}
