const std = @import("std");
const zing = @import("../root.zig");

const SinContext = struct {
    frequency: f32,
    length: usize,
};

fn sin_impl(_: []const f32, sample_rate: usize, track_data_allocator: zing.TrackDataAllocator, context: SinContext) anyerror!zing.TrackData {
    const shift = 2 * std.math.pi * context.frequency / @as(f32, @floatFromInt(sample_rate));

    var sample = try track_data_allocator.alloc(context.length);
    for (0..context.length) |i| {
        sample[i] = std.math.sin(@as(f32, @floatFromInt(i)) * shift);
    }
    return sample;
}

pub fn sin(frequency: f32, length: usize) zing.WithContext(SinContext) {
    return .{
        .call = sin_impl,
        .context = .{
            .frequency = frequency,
            .length = length,
        },
    };
}

test "sin" {
    var track = try zing.Track.init(64000, std.testing.allocator);
    try track.mutateContext(sin(200, 64000));
    try track.save();
    track.free();
}
