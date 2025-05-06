const std = @import("std");
const zing = @import("../root.zig");

pub fn sin(frequency: f32, length: usize) zing.TransformFunction {
    return struct {
        pub fn call(_: []const f32, sample_rate: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            const shift = 2 * std.math.pi * frequency / @as(f32, @floatFromInt(sample_rate));

            var sample = try track_data_allocator.alloc(length);
            for (0..length) |i| {
                sample[i] = std.math.sin(@as(f32, @floatFromInt(i)) * shift);
            }
            return sample;
        }
    }.call;
}

test "sin" {
    var track = try zing.Track.init(64000, std.testing.allocator);
    try track.mutate(sin(200, 64000));
    try track.save();
    track.free();
}
