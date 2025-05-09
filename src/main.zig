const std = @import("std");
const zing = @import("root.zig");
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const opts: zing.TrackOptions = .{
        .sample_rate = 48000,
        .allocator = allocator,
    };

    var t1 = try zing.sin(opts, 100, 1);
    var t2 = try zing.silence(opts, 1);
    try zing.push(
        &t2,
        try zing.sin(opts, 200, 2),
    );

    try zing.push(
        &t1,
        t2,
    );

    try t1.save();
    t1.free();
}
