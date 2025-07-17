const std = @import("std");
const builtin = @import("builtin");
const zaudio = @import("zaudio");
const testing = std.testing;

pub const TrackData = []f32;

pub const TrackOptions = struct {
    sample_rate: usize,
    allocator: std.mem.Allocator,
};

const ZaudioAllocationData = struct {
    allocator: std.mem.Allocator,
    allocations: std.AutoHashMap(usize, usize),
    mutex: std.Thread.Mutex,
};

// fn onMalloc (len: usize, user_data: ?*anyopaque) callconv(.C) ?*anyopaque {
//    const allocator: std.mem.Allocator = @ptrCast(user_data.?);
//    const mem = allocator.alignedAlloc(
//        u8, 16, len,
//    ) catch @panic("zing: out of memory");
//
//    return
//}

pub const Track = struct {
    data: []f32,
    sample_rate: usize,
    allocator: std.mem.Allocator,
    // zaudioAllocationData: *ZaudioAllocationData,

    pub fn init(opts: TrackOptions) !Track {
        return .{
            .data = try opts.allocator.alloc(f32, 0),
            .sample_rate = opts.sample_rate,
            .allocator = opts.allocator,
        };
    }

    pub fn alloc(self: *Track, samples: usize) ![]f32 {
        return self.allocator.alloc(f32, samples);
    }

    pub fn free(self: *Track) void {
        self.allocator.free(self.data);
    }

    /// Returns a new track that must also be freed
    pub fn duplicate(self: *Track) !Track {
        var new_track = Track{
            .data = undefined,
            .sample_rate = self.sample_rate,
            .allocator = self.allocator,
        };

        new_track.data = try new_track.allocator.alloc(f32, self.data.len);
        @memcpy(new_track.data, self.data);

        return new_track;
    }

    fn sample_rate_as_string(self: *Track, buf: *[16]u8) []u8 {
        const len = std.fmt.formatIntBuf(buf, self.sample_rate, 10, .lower, .{});
        return buf[0..len];
    }

    fn save_temp_binary(self: *Track) !void {
        const file = try std.fs.cwd().createFile(".zing.temp", .{ .read = true });
        defer file.close();
        const writer = file.writer();
        for (self.data) |num| {
            for (std.mem.asBytes(&num)) |byte| {
                try writer.writeByte(byte);
            }
        }
    }

    // Each unicode braile has 2 columns
    const show_columns = 80;
    const show_x_size = show_columns * 2;
    // Each unicode braile has 4 rows
    const show_rows = 20;
    const show_y_size = show_rows * 4;
    const show_y_max = show_y_size - 1;

    /// Renders the track to console
    pub fn show(self: *Track) !void {
        var old_output_cp: c_uint = undefined;
        if (comptime builtin.target.os.tag == .windows) {
            old_output_cp = std.os.windows.kernel32.GetConsoleOutputCP();
            _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
        }

        const stdOut = std.io.getStdOut().writer();
        const chunks: usize = self.data.len / self.sample_rate;
        const sample_interval: usize = self.sample_rate / show_x_size;

        // Could eventually pack bits into bytes to save space
        var out_grid: [show_x_size][show_y_size]bool = undefined;
        var current_chunk: usize = 0;
        while (current_chunk < chunks) {
            for (0..show_x_size) |x| {
                // make them all 0 to 2 because its just easier to work with
                const middle_sample = self.data[
                    (x * sample_interval) + (sample_interval / 2) + (current_chunk * self.sample_rate)
                ] + 1;

                // since middle_sample is 0 to 2, cut in half to be 0 to 1 then
                // bound to be 0 to show_rows-1
                const y: usize = @intFromFloat(middle_sample *
                    show_y_max * 0.5);

                // Just invert so that because since its printed line by line
                // out_grid[0][0] is the top left corner
                out_grid[x][show_y_max - y] = true;
            }

            try stdOut.writeByte('\n');
            try stdOut.writeAll("_" ** show_columns);
            try stdOut.writeByte('\n');

            // multiply by 3 for the braile char bytes, add an additional
            // show_rows for the new lines
            var out_buf: [(show_columns * show_rows * 3) + show_rows]u8 = undefined;
            var cursor: usize = 0;
            for (0..show_rows) |row| {
                for (0..show_columns) |col| {
                    const x = col * 2;
                    const y = row * 4;
                    var code_point: u21 = 0x2800;

                    if (out_grid[x][y]) {
                        code_point |= 0b0000_0001;
                    }
                    if (out_grid[x][y + 1]) {
                        code_point |= 0b0000_0010;
                    }
                    if (out_grid[x][y + 2]) {
                        code_point |= 0b0000_0100;
                    }
                    if (out_grid[x][y + 3]) {
                        code_point |= 0b0100_0000;
                    }
                    if (out_grid[x + 1][y]) {
                        code_point |= 0b0000_1000;
                    }
                    if (out_grid[x + 1][y + 1]) {
                        code_point |= 0b0001_0000;
                    }
                    if (out_grid[x + 1][y + 2]) {
                        code_point |= 0b0010_0000;
                    }
                    if (out_grid[x + 1][y + 3]) {
                        code_point |= 0b1000_0000;
                    }

                    const res = try std.unicode.utf8Encode(
                        code_point,
                        out_buf[cursor..],
                    );
                    if (res != 3) {
                        return error.GenericError;
                    }
                    cursor += 3;
                }
                out_buf[cursor] = '\n';
                cursor += 1;
            }
            try stdOut.writeAll(out_buf[0..cursor]);
            try stdOut.writeAll("‾" ** show_columns);
            try stdOut.writeByte('\n');
            current_chunk += 1;
        }
        if (comptime builtin.target.os.tag == .windows) {
            _ = std.os.windows.kernel32.SetConsoleOutputCP(old_output_cp);
        }
    }

    /// Plays the track with zaudio
    pub fn play(self: *Track) !void {
        zaudio.init(self.allocator);
        defer zaudio.deinit();

        var engine_config = zaudio.Engine.Config.init();
        const device_config = zaudio.Device.Config.init(.playback);
        engine_config.device = try zaudio.Device.create(null, device_config);

        const engine = try zaudio.Engine.create(engine_config);
        defer engine.destroy();

        const audio_buf = try zaudio.AudioBuffer.create(.{
            .channels = 1,
            .format = .float32,
            .sample_rate = @intCast(self.sample_rate),
            .size_in_frames = self.data.len,
            .data = @ptrCast(self.data),
            .allocation_callbacks = .{
                .user_data = null,
                .onMalloc = null,
                .onRealloc = null,
                .onFree = null,
            },
        });
        defer audio_buf.destroy();

        const sound = try engine.createSoundFromDataSource(
            audio_buf.asDataSourceMut(),
            .{ .looping = true },
            null,
        );
        defer sound.destroy();
        try sound.start();
        std.time.sleep(std.time.ns_per_s);
    }

    /// Saves the track to a `.wav` file with ffmpeg while also writing to a
    /// temporary file called `.zing.temp`
    pub fn save(self: *Track) !void {
        try self.save_temp_binary();
        var buf: [16]u8 = undefined;
        const sample_rate = self.sample_rate_as_string(&buf);
        const args = [_][]const u8{ "ffmpeg", "-f", "f32le", "-ar", sample_rate, "-ac", "1", "-i", ".zing.temp", "output.wav" };

        var child = std.process.Child.init(&args, self.allocator);
        try child.spawn();
        const trash = try child.wait();
        std.debug.print("{}", .{trash});
    }
};
