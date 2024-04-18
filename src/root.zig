const std = @import("std");
const testing = std.testing;

fn ReturnType(comptime lazy_fn: anytype) type {
    const LazyFn = @TypeOf(lazy_fn);
    const info = @typeInfo(LazyFn);
    if (info != .Fn) {
        @compileError("`lazy_fn` must be a function, cannot use `" ++ @typeName(LazyFn) ++ "`.");
    }
    if (info.Fn.params.len != 0) {
        @compileError("`lazy_fn` must be a function of type `fn () T`.");
    }
    return info.Fn.return_type.?;
}

pub fn lazy(comptime lazy_fn: anytype) fn () *ReturnType(lazy_fn) {
    return struct {
        var data: ?Data = undefined;
        const Data = ReturnType(lazy_fn);
        pub fn ptr() *Data {
            return &(data orelse data: {
                data = lazy_fn();
                break :data data.?;
            });
        }
    }.ptr;
}

pub fn constLazy(comptime lazy_fn: anytype) fn () *const ReturnType(lazy_fn) {
    return lazy(lazy_fn);
}

const testHome = constLazy(struct {
    fn f() []const u8 {
        return std.os.getenv("HOME").?;
    }
}.f);

test "home" {
    try testing.expectEqual(@TypeOf(testHome().*), []const u8);
    try testing.expectEqualSlices(u8, testHome().*, std.os.getenv("HOME").?);
}

const testList = lazy(struct {
    fn f() std.ArrayList(u32) {
        return std.ArrayList(u32).initCapacity(std.heap.page_allocator, 4) catch unreachable;
    }
}.f);

fn testAppend(n: u32) void {
    testList().appendAssumeCapacity(n);
}

test "list" {
    try testing.expectEqual(@TypeOf(testList().*), std.ArrayList(u32));
    testList().appendAssumeCapacity(1);
    testAppend(2);
    testList().appendAssumeCapacity(3);
    testAppend(4);
    try testing.expectEqual(testList().popOrNull(), 4);
    try testing.expectEqual(testList().popOrNull(), 3);
    try testing.expectEqual(testList().popOrNull(), 2);
    try testing.expectEqual(testList().popOrNull(), 1);
    try testing.expectEqual(testList().popOrNull(), null);
}

const testNum = lazy(struct {
    fn f() u32 {
        return 42;
    }
}.f);

test "num" {
    try testing.expectEqual(@TypeOf(testNum().*), u32);
    try testing.expectEqual(testNum().*, 42);
    testNum().* += 1;
    try testing.expectEqual(testNum().*, 43);
    testNum().* = 77;
    try testing.expectEqual(testNum().*, 77);
}
