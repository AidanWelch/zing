const std = @import("std");
const zing = @import("../root.zig");

// Consumes the `consumable_track`, concatenate/appends the `consumable_track`
// to the end of the calling track.
pub fn push(track: *zing.Track, consumable_track: zing.Track) !void {
    defer consumable_track.free();
    var sample = try track.track_data_allocator.alloc(track.data.len + consumable_track.data.len);
    @memcpy(sample[0..track.data.len], track.data);
    @memcpy(sample[track.data.len..], consumable_track.data);
    track.free();
    track.data = sample;
}
