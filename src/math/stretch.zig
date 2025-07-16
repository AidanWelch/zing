const std = @import("std");
const zing = @import("../root.zig");

// Stretches the track to be its current length * f64, through either speeding
// up or slowing down
pub fn stretch(track: *zing.Track, speed: f64) !void {
    const track_len_float: f64 = @floatFromInt(track.data.len);
    const new_size: usize = @intFromFloat(track_len_float / speed);
    const sample_offset: f64 = track_len_float / @as(f64, @floatFromInt(new_size));
    var sample = try track.track_data_allocator.alloc(new_size);
    for (0..new_size) |i| {
        const i_float: f64 = @floatFromInt(i);
        sample[i] = track.data[@intFromFloat(i_float * sample_offset)];
    }
    track.free();
    track.data = sample;
}
