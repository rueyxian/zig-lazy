const std = @import("std");
const debug = std.debug;
const Thread = std.Thread;
const lazy = @import("lazy").lazy;

const getNum = lazy(false, struct {
    fn f() u64 {
        return @as(u64, @intCast(std.time.timestamp())) % 10000;
    }
}.f);

pub fn main() !void {
    const start = getNum().*;
    const thread_count: usize = 7;
    const loop_count: usize = 1000;
    const Context = struct {
        mutex: Thread.Mutex = .{},
        fn run(ctx: *@This()) void {
            for (0..loop_count) |_| {
                ctx.mutex.lock();
                defer ctx.mutex.unlock();
                getNum().* += 1;
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
    debug.assert(getNum().* == start + (thread_count * loop_count));
    debug.print("start : {}\n", .{start});
    debug.print("added : {}\n", .{thread_count * loop_count});
    debug.print("result: {}\n", .{getNum().*});
}
