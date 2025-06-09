const std = @import("std");
const zaudio = @import("zaudio");
const testing = std.testing;

pub const TrackData = []f32;

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

pub const TrackOptions = struct {
    sample_rate: usize,
    allocator: std.mem.Allocator,
};


const ZaudioAllocationData = struct {
    allocator: std.mem.Allocator,
    allocations: std.AutoHashMap(usize, usize),
    mutex: std.Thread.Mutex,
};

fn onMalloc (len: usize, user_data: ?*anyopaque) callconv(.C) ?*anyopaque {
    const allocator: std.mem.Allocator = @ptrCast(user_data.?);
    const mem = allocator.alignedAlloc(
        u8, 16, len,
    ) catch @panic("zing: out of memory");

    return
}

pub const Track = struct {
    data: []f32,
    sample_rate: usize,
    track_data_allocator: TrackDataAllocator,
    engine: *zaudio.Engine,
    zaudioAllocationData: *ZaudioAllocationData,

    pub fn init(opts: TrackOptions) !Track {
        const track_data_allocator = TrackDataAllocator{
            .allocator = opts.allocator,
        };

        engine_config = zaudio.Engine.Config.init();

        return .{
            .data = try track_data_allocator.alloc(0),
            .sample_rate = opts.sample_rate,
            .track_data_allocator = track_data_allocator,
            .engine = try zaudio.Engine.create(.{
                .allocation_callbacks = .{
                    .user_data = opts.allocator,
                },
            }),
        };
    }

    pub fn free(self: Track) void {
        self.track_data_allocator.free(self.data);
        zaudio.deinit();
    }

    /// Returns a new track that must also be freed
    pub fn duplicate(self: Track) !Track {
        var new_track = Track{
            .data = undefined,
            .sample_rate = self.sample_rate,
            .track_data_allocator = self.track_data_allocator,
        };

        new_track.data = try new_track.track_data_allocator.alloc(self.data.len);
        @memcpy(new_track.data, self.data);

        return new_track;
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

        defer engine.destroy();

        const audio_buf = try zaudio.AudioBuffer.create(.{
            .channels = 1,
            .format = .float32,
            .sample_rate = self.sample_rate,
            .size_in_frames = self.data.len,
            .data = self.data,
        });
        defer audio_buf.destroy();

        const sound = try engine.createSoundFromDataSource(
            audio_buf.asDataSource(),
            .{.looping = true},
            sgroup: ?*SoundGroup,
            );

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
