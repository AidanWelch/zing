const std = @import("std");
const zing = @import("../root.zig");

// Consumes the `consumable_track`, concatenate/appends the `consumable_track`
// to the end of the calling track.
pub fn push(consumable_track: zing.Track) zing.WithContext(zing.Track) {
    return .{
        .call = struct {
            pub fn call(
                data: []const f32,
                _: usize,
                track_data_allocator: zing.TrackDataAllocator,
                context: zing.Track,
            ) anyerror!zing.TrackData {
                defer context.free();
                var sample = try track_data_allocator.alloc(data.len + context.data.len);
                @memcpy(sample[0..data.len], data);
                @memcpy(sample[data.len..], context.data);
                return sample;
            }
        }.call,
        .context = consumable_track,
    };
}
