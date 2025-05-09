const std = @import("std");
const zing = @import("../root.zig");

const SlopeContext = struct {
    step: f32,
    length: usize,
};

fn slope_impl(
    _: []const f32,
    _: usize,
    track_data_allocator: zing.TrackDataAllocator,
    context: SlopeContext,
) anyerror!zing.TrackData {
    var sample = try track_data_allocator.alloc(context.length);
    for (0..context.length) |i| {
        sample[i] = @as(f32, @floatFromInt(i)) * context.step;
    }
    return sample;
}

// for x < length => x * step
pub fn slope(step: f32, length: usize) zing.WithContext(SlopeContext) {
    return .{
        .call = slope_impl,
        .context = .{
            .step = step,
            .length = length,
        },
    };
}

test "slope" {
    var track = try zing.Track.init(64000, std.testing.allocator);
    try track.mutate(slope(1, 64000));
    try track.save();
    track.free();
}
