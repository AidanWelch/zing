const std = @import("std");
const zing = @import("../root.zig");

const LengthContext = usize;

pub fn silence(length: usize) zing.WithContext(LengthContext) {
    return .{
        .call = struct {
            pub fn call(
                _: []const f32,
                _: usize,
                track_data_allocator: zing.TrackDataAllocator,
                context: LengthContext,
            ) anyerror!zing.TrackData {
                var sample = try track_data_allocator.alloc(context);
                for (0..context) |i| {
                    sample[i] = 0;
                }
                return sample;
            }
        }.call,
        .context = length,
    };
}
