const std = @import("std");
const testing = std.testing;

pub const TrackData = []f32;

pub const TransformFunction = fn (data: []const f32, sample_rate: usize, track_data_allocator: TrackDataAllocator) anyerror!TrackData;

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

    pub fn init(sample_rate: usize, allocator: std.mem.Allocator) !Track {
        const track_data_allocator = TrackDataAllocator{
            .allocator = allocator,
        };

        return .{
            .data = try track_data_allocator.alloc(0),
            .sample_rate = sample_rate,
            .track_data_allocator = track_data_allocator,
        };
    }

    pub fn free(self: Track) void {
        self.track_data_allocator.free(self.data);
    }

    /// Returns a new track that must also be freed
    pub fn duplicate(self: Track) Track {
        var new_track = Track{
            .sample_rate = self.sample_rate,
            .track_data_allocator = self.track_data_allocator,
        };

        new_track.data = try new_track.track_data_allocator.alloc(self.val.data.len);
        @memcpy(new_track.data, self.val.data);

        return new_track;
    }

    /// Calls transform_func on the track and overwrites it.
    pub fn mutate(self: *Track, transform_func: TransformFunction) !void {
        const new_data = try transform_func(
            self.data,
            self.sample_rate,
            self.track_data_allocator,
        );
        self.track_data_allocator.free(self.data);
        self.data = new_data;
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

test "play sin wave" {
    var track = try Track.init(64000, std.testing.allocator);
    try track.mutate(struct {
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
    track.free();
}

test "save sin wave" {
    var track = try Track.init(64000, std.testing.allocator);
    try track.mutate(struct {
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
    track.free();
}
