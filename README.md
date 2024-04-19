# zig-lazy

A lazy initialization Zig library. 

## Goals

[Lazy initialization](https://en.wikipedia.org/wiki/Lazy_initialization) not only mitigates program start-up overhead by deferring the initialization process until needed, thus improving performance, but it also resolves data dependency issues, such as reading data from files that cannot be accomplished at compile time.

## Features

This library provides two functions, `lazy` and `constLazy`:

- Passing functions of type `fn () T` into `lazy` returns `*T`.
- Passing functions of type `fn () T` into `constLazy` returns `*const T`.

Lazy initialization is often used in conjunction with multithreading. To avoid unnecessary abstraction, however, the invocations of these two functions aren't thread-safe. Users are accountable for handling race conditions on their own.

## Installation

To add `zig-lazy` to your `build.zig.zon`:

```
.{
    .name = "<YOUR PROGRAM>",
    .version = "0.0.0",
    .dependencies = .{
        .lazy = .{
            .url = "https://github.com/rueyxian/zig-lazy/archive/refs/tags/v0.0.0.tar.gz",
            .hash = "<CORRECT HASH WILL BE SUGGESTED>",
        },
    },
}
```

To add `zig-lazy` to your `build.zig`:

```
const dep_lazy = b.dependency("lazy", .{
    .target = target,
    .optimize = optimize,
});
exe.addModule("lazy", dep_lazy("lazy"));
```

## Example

To run an example:

```
$ zig build <EXAMPLE>
```

where `<EXAMPLE>` is one of:

- `example_home`
- `example_list`
- `example_threaded`

### Example: Home

```zig
const std = @import("std");
const debug = std.debug;
const lazy = @import("lazy").lazy;

const getHome = lazy(struct {
    fn f() []const u8 {
        return std.os.getenv("HOME").?;
    }
}.f);

pub fn main() !void {
    debug.print("home: {s}\n", .{getHome().*});
}

```
Output:

```
home: /Users/foobar
```
Note: The output may differ from that of your machine.

### Example: Array List

```zig
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
```
Output:

```
6
5
4
3
2
1
null
```
### Example: Threaded

```zig
const std = @import("std");
const debug = std.debug;
const Thread = std.Thread;
const lazy = @import("lazy").lazy;

const getNum = lazy(struct {
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
```
Output:

```
start : 4326
added : 7000
result: 11326
```
Note: The output may differ from that of your machine.