const std = @import("std");
const testing = std.testing;

pub const TrackData = []f32;

pub const TransformFunction = fn (data: []f32, sample_rate: usize, track_data_allocator: TrackDataAllocator) anyerror!TrackData;

pub const TrackDataAllocator = struct {
    allocator: std.mem.Allocator,

    /// Allocate the track data to be returned by the transform function.  It
    /// should only be called once per transform function, and the allocated
    /// data must be returned from the transform function.
    pub fn alloc(self: TrackDataAllocator, length: usize) !TrackData {
        return self.allocator.alloc(f32, length);
    }

    fn free(self: TrackDataAllocator, samples: TrackData) void {
        return self.allocator.free(samples);
    }
};

pub const Track = struct {
    data: []f32,
    sample_rate: usize,
    track_data_allocator: TrackDataAllocator,

    pub fn init(sample_rate: usize, allocator: std.mem.Allocator) TrackResult {
        const track_data_allocator = TrackDataAllocator{
            .allocator = allocator,
        };

        const track_data = track_data_allocator.alloc(0) catch |err|
            return .{ .err = err };

        return TrackResult{ .val = Track{
            .data = track_data,
            .sample_rate = sample_rate,
            .track_data_allocator = track_data_allocator,
        } };
    }

    fn sample_rate_as_string(self: Track, buf: *[16]u8) []u8 {
        const len = std.fmt.formatIntBuf(buf, self.sample_rate, 10, .lower, .{});
        return buf[0..len];
    }

    fn save_temp_binary(self: Track) !void {
        const file = try std.fs.cwd().createFile(".zing.temp", .{ .read = true });
        defer file.close();
        const writer = file.writer();
        for (self.data) |num| {
            for (std.mem.asBytes(&num)) |byte| {
                try writer.writeByte(byte);
            }
        }
    }

    /// Plays the track with ffplay by writing it to a file called
    /// `.zing.temp`
    pub fn play(self: Track) !void {
        try self.save_temp_binary();
        var buf: [16]u8 = undefined;
        const sample_rate = self.sample_rate_as_string(&buf);
        const args = [_][]const u8{ "ffplay", "-f", "f32le", "-ar", sample_rate, ".zing.temp" };

        var child = std.process.Child.init(&args, self.track_data_allocator.allocator);
        try child.spawn();
        const trash = try child.wait();
        std.debug.print("{}", .{trash});
    }

    /// Saves the track to a `.wav` file with ffmpeg while also writing to a
    /// temporary file called `.zing.temp`
    pub fn save(self: Track) !void {
        try self.save_temp_binary();
        var buf: [16]u8 = undefined;
        const sample_rate = self.sample_rate_as_string(&buf);
        const args = [_][]const u8{ "ffmpeg", "-f", "f32le", "-ar", sample_rate, "-ac", "1", "-i", ".zing.temp", "output.wav" };

        var child = std.process.Child.init(&args, self.track_data_allocator.allocator);
        try child.spawn();
        const trash = try child.wait();
        std.debug.print("{}", .{trash});
    }
};

pub const TrackResult = union(enum) {
    err: anyerror,
    val: Track,

    pub fn free(self: TrackResult) void {
        switch (self) {
            .val => |data| {
                data.track_data_allocator.free(data.data);
            },
            .err => {},
        }
    }

    /// Returns a new track that must also be freed
    pub fn duplicate(self: TrackResult) TrackResult {
        switch (self) {
            .err => |err| {
                return TrackResult{ .err = err };
            },
        }

        var new_track = Track{
            .sample_rate = self.sample_rate,
            .track_data_allocator = self.track_data_allocator,
        };

        new_track.data = new_track.track_data_allocator.alloc(self.val.data.len) catch |err| {
            return TrackResult{ .err = err };
        };

        @memcpy(new_track.data, self.val.data);

        return TrackResult{ .val = new_track };
    }

    /// Calls transform_func on the track and overwrites it.
    pub fn mutate(self: *TrackResult, transform_func: TransformFunction) TrackResult {
        switch (self.*) {
            .err => return self.*,
            else => {},
        }

        const transform_result = transform_func(
            self.val.data,
            self.val.sample_rate,
            self.val.track_data_allocator,
        ) catch |err| {
            self.val.track_data_allocator.free(self.val.data);
            self.* = TrackResult{ .err = err };
            return self.*;
        };
        self.val.track_data_allocator.free(self.val.data);

        self.val.data = transform_result;
        return self.*;
    }

    /// Plays the track with ffplay by writing it to a file called
    /// `.zing.temp`
    pub fn play(self: TrackResult) !void {
        switch (self) {
            .val => |data| {
                try data.play();
            },
            .err => |err| {
                return err;
            },
        }
    }

    /// Saves the track to a `.wav` file with ffmpeg while also writing to a
    /// temporary file called `.zing.temp`
    pub fn save(self: TrackResult) !void {
        switch (self) {
            .val => |data| {
                try data.save();
            },
            .err => |err| {
                return err;
            },
        }
    }
};

test "get error" {
    var track = Track.init(64000, std.testing.failing_allocator);
    defer track.free();
    _ = track.mutate(struct {
        pub fn call(
            _: []f32,
            sample_rate: usize,
            track_data_allocator: TrackDataAllocator,
        ) anyerror!TrackData {
            var sample = try track_data_allocator.alloc(sample_rate);

            for (0..sample_rate) |i| {
                const out: f32 = @floatFromInt(i);
                sample[i] = std.math.sin(out * 0.1);
            }

            return sample;
        }
    }.call);

    const res = track.save();
    try testing.expectError(std.mem.Allocator.Error.OutOfMemory, res);
}

test "play sin wave" {
    var track = Track.init(64000, std.testing.allocator);
    defer track.free();
    _ = track.mutate(struct {
        pub fn call(
            _: []f32,
            sample_rate: usize,
            track_data_allocator: TrackDataAllocator,
        ) anyerror!TrackData {
            var sample = try track_data_allocator.alloc(sample_rate);

            for (0..sample_rate) |i| {
                const out: f32 = @floatFromInt(i);
                sample[i] = std.math.sin(out * 0.1);
            }

            return sample;
        }
    }.call);

    try track.play();
}

test "save sin wave" {
    var track = Track.init(64000, std.testing.allocator);
    defer track.free();
    _ = track.mutate(struct {
        pub fn call(
            _: []f32,
            sample_rate: usize,
            track_data_allocator: TrackDataAllocator,
        ) anyerror!TrackData {
            var sample = try track_data_allocator.alloc(sample_rate);

            for (0..sample_rate) |i| {
                const out: f32 = @floatFromInt(i);
                sample[i] = std.math.sin(out * 0.1);
            }

            return sample;
        }
    }.call);

    try track.save();
}
