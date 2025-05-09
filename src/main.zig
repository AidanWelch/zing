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

    const bass_beat = try zing.sin(opts, 55, 3);

    var t1 = try zing.square(opts, 3, 3);
    for (0..t1.data.len) |i| {
        if (t1.data[i] < 0) {
            t1.data[i] = 0;
        }
    }

    try zing.multiply(
        &t1,
        bass_beat,
    );

    try t1.save();
    t1.free();
}
