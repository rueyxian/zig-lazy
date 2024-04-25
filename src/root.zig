const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

fn ReturnType(comptime init_fn: anytype) type {
    const InitFn = @TypeOf(init_fn);
    const info = @typeInfo(InitFn);
    if (info != .Fn) {
        @compileError("`init_fn` must be a function, cannot use `" ++ @typeName(InitFn) ++ "`.");
    }
    if (info.Fn.params.len != 0) {
        @compileError("`init_fn` must be a function of type `fn () T`.");
    }
    return info.Fn.return_type.?;
}

pub fn Lazy(comptime T: type, comptime is_const: bool) type {
    if (is_const) {
        return fn () *const T;
    }
    return fn () *T;
}

pub fn autoLazy(comptime init_fn: anytype) Lazy(ReturnType(init_fn), false) {
    return Static(ReturnType(init_fn), false, init_fn).ptr;
}

pub fn autoConstLazy(comptime init_fn: anytype) Lazy(ReturnType(init_fn), true) {
    return Static(ReturnType(init_fn), true, init_fn).ptr;
}

pub fn lazy(comptime T: type, comptime is_const: bool, comptime init_fn: fn () T) Lazy(T, is_const) {
    return Static(T, is_const, init_fn).ptr;
}

fn Static(comptime T: type, comptime is_const: bool, comptime init_fn: fn () T) type {
    return struct {
        var done: bool = false;
        var value: T = undefined;
        const Pointer = if (is_const) *const T else *T;
        pub fn ptr() Pointer {
            if (done == false) {
                initSlow(T, init_fn, &done, &value);
            }
            return &value;
        }
    };
}

fn initSlow(comptime T: type, comptime init_fn: fn () T, done: *bool, value: *T) void {
    @setCold(true);
    value.* = init_fn();
    done.* = true;
}

const testHome = autoConstLazy(struct {
    fn f() []const u8 {
        return std.os.getenv("HOME").?;
    }
}.f);

test "home" {
    try testing.expectEqual(@TypeOf(testHome()), *const []const u8);
    try testing.expectEqualSlices(u8, testHome().*, std.os.getenv("HOME").?);
}

const testList = lazy(std.ArrayList(u32), false, struct {
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

const testNum = autoLazy(struct {
    fn f() u64 {
        return @as(u64, @intCast(std.time.timestamp())) % 10000;
    }
}.f);

test "threaded" {
    const Thread = std.Thread;
    const Mutex = std.Thread.Mutex;
    const start = testNum().*;
    const thread_count: usize = 7;
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
