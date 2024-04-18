# zig-lazy
A [lazy initialization](https://en.wikipedia.org/wiki/Lazy_initialization) Zig library.





## Example


To run an example:

```
$ zig build <EXAMPLE>
```

where `<EXAMPLE>` is one of:

- `example_home`
- `example_list`

#### Example: Home

```
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


#### Example: Array List

```
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

```