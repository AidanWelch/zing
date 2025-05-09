const std = @import("std");
const zing = @import("../root.zig");

pub fn sin(opts: zing.TrackOptions, frequency: f32, seconds: f64) !zing.Track {
    var track = try zing.Track.init(opts);

    const length: usize = @intFromFloat(@as(f64, @floatFromInt(track.sample_rate)) * seconds);

    const shift = 2 * std.math.pi * frequency / @as(f32, @floatFromInt(track.sample_rate));

    var sample = try track.track_data_allocator.alloc(length);

    for (0..length) |i| {
        sample[i] = std.math.sin(@as(f32, @floatFromInt(i)) * shift);
    }

    track.data = sample;

    return track;
}

test "sin" {
    var track = try sin(.{ .sample_rate = 64000, .allocator = std.testing.allocator }, 200, 64000);
    try track.save();
    track.free();
}
