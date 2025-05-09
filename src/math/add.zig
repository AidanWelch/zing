const std = @import("std");
const zing = @import("../root.zig");

// Consumes the input track, returns the tracks with each of their points added.
pub fn add(consumable_track: zing.Track) zing.WithContext(zing.Track) {
    return .{
        .call = struct {
            pub fn call(
                data: []const f32,
                _: usize,
                track_data_allocator: zing.TrackDataAllocator,
                context: zing.Track,
            ) anyerror!zing.TrackData {
                defer context.free();
                var sample = try track_data_allocator.alloc(@max(data.len, context.data.len));
                for (0..sample.len) |i| {
                    sample[i] = 0;
                    if (i < data.len) {
                        sample[i] += data[i];
                    }
                    if (i < context.data.len) {
                        sample[i] += context.data[i];
                    }
                }
                return sample;
            }
        }.call,
        .context = consumable_track,
    };
}
