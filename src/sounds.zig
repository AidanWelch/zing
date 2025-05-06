const std = @import("std");
const zing = @import("root.zig");

pub fn index(step: f32, length: usize) zing.TransformFunction {
    return struct {
        pub fn call(_: []f32, _: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            var sample = try track_data_allocator.alloc(length);
            for (0..length) |i| {
                sample[i] = @as(f32, @floatFromInt(i)) * step;
            }
            return sample;
        }
    }.call;
}

pub fn sin(frequency: f32, length: usize) zing.TransformFunction {
    return struct {
        pub fn call(data: []f32, sample_rate: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            const shift = 2 * std.math.pi * frequency / @as(f32, @floatFromInt(sample_rate));

            var sample = try track_data_allocator.alloc(length);
            for (0..length) |i| {
                sample[i] = std.math.sin(data[i] * shift);
            }
            return sample;
        }
    }.call;
}

test "sin" {
    var track = try zing.Track.init(64000, std.testing.allocator);
    try track.mutate(index(1, 64000));
    try track.mutate(sin(200, 64000));
    try track.play();
    track.free();
}

pub fn multiply(multiplier: f32) zing.TransformFunction {
    return struct {
        pub fn call(data: []f32, _: usize, track_data_allocator: zing.TrackDataAllocator) anyerror!zing.TrackData {
            var sample = try track_data_allocator.alloc(data.len);
            for (0..data.len) |i| {
                sample[i] = data[i] * multiplier;
            }
            return sample;
        }
    }.call;
}
