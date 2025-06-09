const std = @import("std");
const zing = @import("../root.zig");

pub fn sawtooth(opts: zing.TrackOptions, frequency: f32, seconds: f64) !zing.Track {
    var track = try zing.Track.init(opts);

    const length: usize = @intFromFloat(@as(f64, @floatFromInt(track.sample_rate)) * seconds);

    const period = frequency / @as(f32, @floatFromInt(track.sample_rate));

    var sample = try track.track_data_allocator.alloc(length);

    for (0..length) |i| {
        sample[i] = 2 * ((i / period) -
            @floor(i / period));
    }

    track.data = sample;

    return track;
}
