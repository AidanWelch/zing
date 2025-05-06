const std = @import("std");
const zing = @import("../root.zig");

pub fn silence(length: usize) zing.TransformFunction {
    return struct {
        pub fn call(_: []const f32, _: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            var sample = try track_data_allocator.alloc(length);
            for (0..length) |i| {
                sample[i] = 0;
            }
            return sample;
        }
    }.call;
}
