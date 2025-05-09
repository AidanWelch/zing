const std = @import("std");
const zing = @import("root.zig");
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var track = try zing.Track.init(48000, allocator);
    try track.mutateContext(zing.sin(100, 48000));

    var t2 = try track.duplicate();
    try t2.mutate(zing.invert);
    try t2.mutateContext(zing.scale(0.9));

    try track.mutateContext(zing.add(t2));

    try track.save();
    track.free();
}
