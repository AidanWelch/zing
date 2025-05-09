const std = @import("std");
const zing = @import("../root.zig");

pub fn offset(o: f32) zing.WithContext(f32) {
    return .{
        .call = struct {
            pub fn call(
                data: []const f32,
                _: usize,
                track_data_allocator: zing.TrackDataAllocator,
                context: f32,
            ) anyerror!zing.TrackData {
                var sample = try track_data_allocator.alloc(data.len);
                for (0..data.len) |i| {
                    sample[i] = data[i] + context;
                }
                return sample;
            }
        }.call,
        .context = o,
    };
}
