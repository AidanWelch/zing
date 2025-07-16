const std = @import("std");
const zing = @import("../root.zig");

// Consumes the `consumable_track` track, set the `track` with each of their
// points added.
pub fn add(track: *zing.Track, consumable_track: zing.Track) !void {
    defer consumable_track.free();
    var sample = try track.alloc(@max(track.data.len, consumable_track.data.len));
    for (0..sample.len) |i| {
        sample[i] = 0;
        if (i < track.data.len) {
            sample[i] += track.data[i];
        }
        if (i < consumable_track.data.len) {
            sample[i] += consumable_track.data[i];
        }
    }
    track.free();
    track.data = sample;
}
