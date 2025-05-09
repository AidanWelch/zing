const std = @import("std");
const zing = @import("../root.zig");

pub fn scale(track: zing.Track, scalar: f32) void {
    for (0..track.data.len) |i| {
        track.data[i] *= scalar;
    }
}
