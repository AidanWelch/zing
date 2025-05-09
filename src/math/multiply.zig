const std = @import("std");
const zing = @import("../root.zig");

// Consumes the input track, returns the tracks with each of their points
// multiplied.  If one track is longer than the other the remaining is just
// multiplied by 1.
pub fn multiply(track: *zing.Track, consumable_track: zing.Track) !void {
    defer consumable_track.free();
    var sample = try track.track_data_allocator.alloc(@max(track.data.len, consumable_track.data.len));
    for (0..sample.len) |i| {
        sample[i] = 1;
        if (i < track.data.len) {
            sample[i] *= track.data[i];
        }
        if (i < consumable_track.data.len) {
            sample[i] *= consumable_track.data[i];
        }
    }
    track.data = sample;
}
