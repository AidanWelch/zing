const std = @import("std");
const zing = @import("../root.zig");

// Consumes the input track, returns the tracks with each of their points added.
pub fn add(consumable_track: zing.Track) zing.TransformFunction {
    return struct {
        pub fn call(data: []const f32, _: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            defer consumable_track.free();
            var sample = try track_data_allocator.alloc(@max(data.len, consumable_track.data.len));
            for (0..sample.len) |i| {
                sample[i] = 0;
                if (i < data.len) {
                    sample[i] += data[i];
                }
                if (i < consumable_track.data.len) {
                    sample[i] += consumable_track.data[i];
                }
            }
            return sample;
        }
    }.call;
}
