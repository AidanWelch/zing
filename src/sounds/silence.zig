const std = @import("std");
const zing = @import("../root.zig");

pub fn silence(opts: zing.TrackOptions, seconds: f64) !zing.Track {
    var track = try zing.Track.init(opts);

    const length: usize = @intFromFloat(@as(f64, @floatFromInt(track.sample_rate)) * seconds);

    var sample = try track.alloc(length);
    for (0..length) |i| {
        sample[i] = 0;
    }

    track.data = sample;

    return track;
}
