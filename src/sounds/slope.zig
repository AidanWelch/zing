const std = @import("std");
const zing = @import("../root.zig");

// for x < length => x * step
pub fn slope(step: f32, length: usize) zing.TransformFunction {
    return struct {
        pub fn call(_: []const f32, _: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            var sample = try track_data_allocator.alloc(length);
            for (0..length) |i| {
                sample[i] = @as(f32, @floatFromInt(i)) * step;
            }
            return sample;
        }
    }.call;
}

test "slope" {
    var track = try zing.Track.init(64000, std.testing.allocator);
    try track.mutate(slope(1, 64000));
    try track.save();
    track.free();
}
