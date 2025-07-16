const std = @import("std");
const zing = @import("../root.zig");

pub fn square(opts: zing.TrackOptions, frequency: f32, seconds: f64) !zing.Track {
    var track = try zing.Track.init(opts);

    const length: usize = @intFromFloat(@as(f64, @floatFromInt(track.sample_rate)) * seconds);

    const shift = frequency / @as(f32, @floatFromInt(track.sample_rate));

    var sample = try track.alloc(length);

    for (0..length) |i| {
        const fi = @as(f32, @floatFromInt(i));
        sample[i] = 2 * ((2 * @floor(fi * shift)) - @floor(2 * fi * shift)) + 1;
    }

    track.data = sample;

    return track;
}
