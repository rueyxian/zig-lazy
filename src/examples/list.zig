const std = @import("std");
const debug = std.debug;
const lazy = @import("lazy").lazy;

const getList = lazy(struct {
    fn f() std.ArrayList(u32) {
        return std.ArrayList(u32).initCapacity(std.heap.page_allocator, 4) catch unreachable;
    }
}.f);

fn append(n: u32) void {
    getList().appendAssumeCapacity(n);
}

pub fn main() !void {
    getList().appendAssumeCapacity(1);
    append(2);
    getList().appendAssumeCapacity(3);
    append(3);

    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
}
