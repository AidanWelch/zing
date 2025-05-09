const std = @import("std");
const zing = @import("../root.zig");

pub fn offset(track: zing.Track, o: f32) void {
    for (0..track.data.len) |i| {
        track.data[i] += o;
    }
}
