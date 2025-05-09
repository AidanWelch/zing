const std = @import("std");
const zing = @import("root.zig");
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var track = try zing.Track.init(48000, allocator);
    try track.mutateContext(zing.sin(100, 48000));

    var t2 = try zing.Track.init(48000, allocator);
    try t2.mutateContext(zing.sin(200, 48000));

    try track.mutateContext(zing.push(t2));
    try track.mutateContext(zing.push(try track.duplicate()));

    try track.save();
    track.free();
}
