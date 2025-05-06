const std = @import("std");
const zing = @import("../root.zig");

pub fn scale(scalar: f32) zing.TransformFunction {
    return struct {
        pub fn call(data: []const f32, _: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            var sample = try track_data_allocator.alloc(data.len);
            for (0..data.len) |i| {
                sample[i] = data[i] * scalar;
            }
            return sample;
        }
    }.call;
}
