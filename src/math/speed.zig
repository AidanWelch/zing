const std = @import("std");
const zing = @import("../root.zig");

// Stretches the track to be its current length / speed, through either speeding
// up or slowing down
//
// So a speed of 2 would place twice as fast
pub fn speed(track: *zing.Track, x: f64) !void {
    // I'm not entirely sure what the expected behavior of a 0 or sub 0 speed
    // would be
    if (x <= 0) {
        return error.TrackSpeedCannotBeLessThanOrEqualToZero;
    }
    const track_len_float: f64 = @floatFromInt(track.data.len);
    const new_size: usize = @intFromFloat(track_len_float / x);
    var sample = try track.alloc(new_size);
    for (0..new_size) |i| {
        const i_float: f64 = @floatFromInt(i);
        sample[i] = track.data[@intFromFloat(i_float * x)];
    }
    track.free();
    track.data = sample;
}
