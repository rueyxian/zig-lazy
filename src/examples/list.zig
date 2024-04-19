const std = @import("std");
const debug = std.debug;
const lazy = @import("lazy").lazy;

const getList = lazy(struct {
    fn f() std.ArrayList(u32) {
        var list = std.ArrayList(u32).initCapacity(std.heap.page_allocator, 6) catch unreachable;
        list.appendAssumeCapacity(1);
        list.appendAssumeCapacity(2);
        return list;
    }
}.f);

fn append(n: u32) void {
    getList().appendAssumeCapacity(n);
}

pub fn main() !void {
    getList().appendAssumeCapacity(3);
    append(4);
    getList().appendAssumeCapacity(5);
    append(6);
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
    debug.print("{?}\n", .{getList().popOrNull()});
}
