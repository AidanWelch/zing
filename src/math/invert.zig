const std = @import("std");
const zing = @import("../root.zig");

pub fn invert(track: zing.Track) void {
    for (0..track.data.len) |i| {
        track.data[i] = -track.data[i];
    }
}
