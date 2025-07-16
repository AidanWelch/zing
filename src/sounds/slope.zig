const std = @import("std");
const zing = @import("../root.zig");

// for x < length => x * step
pub fn slope(opts: zing.TrackOptions, step: f32, length: usize) !zing.Track {
    var track = try zing.Track.init(opts);

    var sample = try track.alloc(length);
    for (0..length) |i| {
        sample[i] = @as(f32, @floatFromInt(i)) * step;
    }

    track.data = sample;

    return track;
}

test "slope" {
    var track = try slope(.{ .sample_rate = 64000, .allocator = std.testing.allocator }, 1, 64000);
    try track.save();
    track.free();
}
