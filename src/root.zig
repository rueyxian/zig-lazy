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
    try testing.expectEqual(@TypeOf(testHome()), *const []const u8);
    try testing.expectEqualSlices(u8, testHome().*, std.os.getenv("HOME").?);
}

const testList = lazy(struct {
    fn f() std.ArrayList(u32) {
        var list = std.ArrayList(u32).initCapacity(std.heap.page_allocator, 6) catch unreachable;
        list.appendAssumeCapacity(1);
        list.appendAssumeCapacity(2);
        return list;
    }
}.f);

fn testAppend(n: u32) void {
    testList().appendAssumeCapacity(n);
}

test "list" {
    try testing.expectEqual(@TypeOf(testList()), *std.ArrayList(u32));
    testList().appendAssumeCapacity(3);
    testAppend(4);
    testList().appendAssumeCapacity(5);
    testAppend(6);
    try testing.expectEqual(testList().popOrNull(), 6);
    try testing.expectEqual(testList().popOrNull(), 5);
    try testing.expectEqual(testList().popOrNull(), 4);
    try testing.expectEqual(testList().popOrNull(), 3);
    try testing.expectEqual(testList().popOrNull(), 2);
    try testing.expectEqual(testList().popOrNull(), 1);
    try testing.expectEqual(testList().popOrNull(), null);
}

const testNum = lazy(struct {
    fn f() u64 {
        return @as(u64, @intCast(std.time.timestamp())) % 10000;
    }
}.f);

test "threaded" {
    const Thread = std.Thread;
    const Mutex = Thread.Mutex;
    const start = testNum().*;
    const thread_count: usize = 4;
    const loop_count: usize = 10000;
    const Context = struct {
        mutex: Mutex = .{},
        fn run(ctx: *@This()) void {
            for (0..loop_count) |_| {
                ctx.mutex.lock();
                defer ctx.mutex.unlock();
                testNum().* += 1;
            }
        }
    };
    var ctx = Context{};
    var threads: [thread_count]Thread = undefined;
    for (0..thread_count) |i| {
        threads[i] = try Thread.spawn(.{}, Context.run, .{&ctx});
    }
    for (&threads) |thread| {
        thread.join();
    }
    try testing.expectEqual(testNum().*, start + (thread_count * loop_count));
}
